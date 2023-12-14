---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT


local get_context = LQT.internal.get_context
local FrameExtensions = LQT.FrameExtensions
local IsFrameProxy = LQT.IsFrameProxy
local ApplyFrameProxy = LQT.ApplyFrameProxy


local OverrideMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        if IsFrameProxy(cb) then
            return function(widget, parent)
                widget.lqtOverride = widget.lqtOverride or {}
                if not widget.lqtOverride[context] then
                    cb = ApplyFrameProxy(cb)
                    widget.lqtOverride[context] = true
                    local orig = widget[key] or FrameExtensions[key]
                    widget[key] = function(self, ...)
                        cb(self, orig, ...)
                    end
                end
            end
        else
            return function(widget, parent)
                widget.lqtOverride = widget.lqtOverride or {}
                if not widget.lqtOverride[context] then
                    widget.lqtOverride[context] = true
                    local orig = widget[key] or FrameExtensions[key]
                    widget[key] = function(self, ...)
                        cb(self, orig, ...)
                    end
                end
            end
        end
    end
}

---@class LQT.Override
---@field [string] WidgetMethodKey
LQT.Override = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, OverrideMt)
    end
})
