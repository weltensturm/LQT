---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT


local get_context = LQT.internal.get_context
local IsFrameProxy = LQT.IsFrameProxy
local CompileFrameProxy = LQT.CompileFrameProxy


local OverrideMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        if IsFrameProxy(cb) then
            local compiled = CompileFrameProxy(cb)
            return function(widget, parent)
                widget.lqtOverride = widget.lqtOverride or {}
                if not widget.lqtOverride[context] then
                    local fn = compiled(widget)
                    widget.lqtOverride[context] = true
                    local orig = widget[key]
                    widget[key] = function(self, ...)
                        fn(self, orig, ...)
                    end
                end
            end
        else
            return function(widget, parent)
                widget.lqtOverride = widget.lqtOverride or {}
                if not widget.lqtOverride[context] then
                    widget.lqtOverride[context] = true
                    local orig = widget[key]
                    widget[key] = function(self, ...)
                        cb(self, orig, ...)
                    end
                end
            end
        end
    end
}

---@class LQT.Override
---@field [string] LQT.ClassKey
LQT.Override = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, OverrideMt)
    end
})
