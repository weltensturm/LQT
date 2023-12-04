---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT

local get_context = LQT.internal.get_context
local FrameExtensions = LQT.FrameExtensions
local IsFrameProxy = LQT.IsFrameProxy
local ApplyFrameProxy = LQT.ApplyFrameProxy


---@alias WidgetMethodKey<T> any


---@class LQT.Event
---@field [WowEvent] WidgetMethodKey


local EventMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        return function(widget, parent)
            return FrameExtensions.Events(widget, { [key] = cb }, context)
        end
    end
}

---@type LQT.Event
LQT.Event = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, EventMt)
    end
})

local UnitEventMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        return function(widget, parent)
            return FrameExtensions.UnitEvents(widget, { [key] = cb }, context)
        end
    end
}

---@type LQT.Event
LQT.UnitEvent = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, UnitEventMt)
    end
})


---@alias LQT.GenericScript ScriptEditBox | ScriptCheckout | ScriptSlider | ScriptScrollFrame | ScriptButton

---@class LQT.Script
---@field [LQT.GenericScript] WidgetMethodKey

local ScriptMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        return function(widget, parent)
            return FrameExtensions.Hooks(widget, { [key] = cb }, context)
        end
    end
}

---@type LQT.Script
LQT.Script = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, ScriptMt)
    end
})



---@class LQT.Override
---@field [string] WidgetMethodKey

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

---@type LQT.Override
LQT.Override = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, OverrideMt)
    end
})


---@class LQT.Hook
---@field [string] WidgetMethodKey

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

---@type LQT.Hook
LQT.Hook = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, HookMt)
    end
})


