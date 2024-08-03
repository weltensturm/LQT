---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT



local get_context = LQT.internal.get_context
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

local HOOKS = setmetatable({}, {__mode='k'})
local HOOKS_LIBRARY = setmetatable({}, {__mode='k'})

local EventMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        return function(widget, parent)
            if not HOOKS[widget] then
                HOOKS[widget] = HOOKS[widget] or {}
                widget:HookScript('OnEvent', function(self, event, ...)
                    local handler = HOOKS[self][event]
                    if handler then
                        handler(self, ...)
                    end
                end)
            end
            if not HOOKS[widget][key] then
                widget:RegisterEvent(key)
            end

            HOOKS_LIBRARY[widget] = HOOKS_LIBRARY[widget] or {}

            if IsFrameProxy(cb) then
                local target, targetKey = FrameProxyTargetKey(widget, cb)
                HOOKS_LIBRARY[widget][context] = {
                    [key] = function(_, ...)
                        target[targetKey](target, ...)
                    end
                }
            else
                HOOKS_LIBRARY[widget][context] = { [key] = cb }
            end

            local build = {}
            for context, handlers in pairs(HOOKS_LIBRARY[widget]) do
                if handlers[key] then
                    table.insert(build, handlers[key])
                end
            end
            HOOKS[widget][key] = ChainFunctions(build)
        end
    end
}

---@class LQT.Event
---@field [WowEvent] LQT.ClassKey
LQT.Event = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, EventMt)
    end
})


