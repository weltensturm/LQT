---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT


local get_context = LQT.internal.get_context
local IsFrameProxy = LQT.IsFrameProxy
local CompileFrameProxy = LQT.CompileFrameProxy


local HookMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        if IsFrameProxy(cb) then
            local compiled = CompileFrameProxy(cb)
            return function(widget, parent)
                widget.lqtHook = widget.lqtHook or {}
                if not widget.lqtHook[context] then
                    local fn = compiled(widget)
                    assert(fn, tostring(cb) .. ' is '.. tostring(fn) .. '\n' .. context)
                    widget.lqtHook[context] = context
                    hooksecurefunc(widget, key, fn)
                end
            end
        else
            return function(widget, parent)
                widget.lqtHook = widget.lqtHook or {}
                if not widget.lqtHook[context] then
                    local fn = widget[key]
                    assert(fn, 'Cannot hook '.. tostring(fn) .. '\n' .. context)
                    widget.lqtHook[context] = context
                    hooksecurefunc(widget, key, cb)
                end
            end
        end
    end
}

---@class LQT.Hook
---@field [string] LQT.ClassKey
LQT.Hook = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, HookMt)
    end
})


