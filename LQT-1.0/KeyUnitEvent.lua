---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT

local get_context = LQT.internal.get_context
local FrameExtensions = LQT.FrameExtensions
local FrameProxyTargetKey = LQT.FrameProxyTargetKey
local IsFrameProxy = LQT.IsFrameProxy


local ChainFunctions = function(t)
    local fn = nil
    for _, f in pairs(t) do
        local fn_old = fn
        if fn_old then
            fn = function(...)
                fn_old(...)
                f(...)
            end
        else
            fn = f
        end
    end
    return fn
end


local UnitEventMt = {
    lqtKeyCompile = function(key, cb)
        local context = key[2]
        key = key[1]
        return function(self, parent)
            if not self.lqtUnitEvents then
                self.lqtUnitEvents = self.lqtUnitEvents or {}
                self:HookScript('OnEvent', function(self, event, ...)
                    local handler = self.lqtUnitEvents[event]
                    if handler then
                        handler(self, ...)
                    end
                end)
                self.SetEventUnit = self.SetEventUnit or FrameExtensions.SetEventUnit
            end
            self.lqtUnitEventsLibrary = self.lqtUnitEventsLibrary or {}

            if IsFrameProxy(cb) then
                local target, targetKey = FrameProxyTargetKey(self, cb)
                self.lqtUnitEventsLibrary[context or get_context()] = {
                    [key] = function(_, ...)
                        target[targetKey](target, ...)
                    end
                }
            else
                self.lqtUnitEventsLibrary[context or get_context()] = { [key] = cb }
            end

            assert(not self.lqtEvents or not self.lqtEvents[key], 'Event ' .. key .. ' is already registered as non-unit event')
            assert(not self.lqtEventHooks or not self.lqtEventHooks[key], 'Event ' .. key .. ' is already registered as non-unit event hook')

            local build = {}
            for context, handlers in pairs(self.lqtUnitEventsLibrary) do
                if handlers[key] then
                    table.insert(build, handlers[key])
                end
            end
            self.lqtUnitEvents[key] = ChainFunctions(build)

        end
    end
}

---@class LQT.UnitEvent
---@field [WowEvent] LQT.ClassKey
LQT.UnitEvent = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, UnitEventMt)
    end
})
