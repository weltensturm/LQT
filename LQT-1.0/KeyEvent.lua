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


local EventMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        return function(widget, parent)
            if not widget.lqtEventHooks then
                widget.lqtEventHooks = widget.lqtEventHooks or {}
                widget:HookScript('OnEvent', function(self, event, ...)
                    local handler = self.lqtEventHooks[event]
                    if handler then
                        handler(self, ...)
                    end
                end)
            end
            widget.lqtEventHooksLibrary = widget.lqtEventHooksLibrary or {}

            if IsFrameProxy(cb) then
                local target, targetKey = FrameProxyTargetKey(widget, cb)
                widget.lqtEventHooksLibrary[context or get_context()] = {
                    [key] = function(_, ...)
                        target[targetKey](target, ...)
                    end
                }
            else
                widget.lqtEventHooksLibrary[context or get_context()] = { [key] = cb }
            end

            if not widget.lqtEventHooks[key] then
                widget:RegisterEvent(key)
            end

            local build = {}
            for context, handlers in pairs(widget.lqtEventHooksLibrary) do
                if handlers[key] then
                    table.insert(build, handlers[key])
                end
            end
            widget.lqtEventHooks[key] = ChainFunctions(build)
        end
    end
}

---@class LQT.Event
---@field [WowEvent] WidgetMethodKey
LQT.Event = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, EventMt)
    end
})


