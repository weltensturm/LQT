---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT


local get_context = LQT.internal.get_context
local FrameExtensions = LQT.FrameExtensions
local IsFrameProxy = LQT.IsFrameProxy
local ApplyFrameProxy = LQT.ApplyFrameProxy


local HookMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        if IsFrameProxy(cb) then
            return function(widget, parent)
                widget.lqtHook = widget.lqtHook or {}
                if not widget.lqtHook[context] then
                    local fn = ApplyFrameProxy(widget, cb)
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
                    if not fn and FrameExtensions[key] then
                        widget[key] = FrameExtensions[key]
                        fn = widget[key]
                    end
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


