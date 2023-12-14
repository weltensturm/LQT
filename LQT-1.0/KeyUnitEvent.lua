---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT

local get_context = LQT.internal.get_context
local FrameExtensions = LQT.FrameExtensions


local UnitEventMt = {
    lqtKeyCompile = function(self, cb)
        local key = self[1]
        local context = self[2]
        return function(widget, parent)
            return FrameExtensions.UnitEvents(widget, { [key] = cb }, context)
        end
    end
}

---@class LQT.UnitEvent
---@field [WowEvent] WidgetMethodKey
LQT.UnitEvent = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, UnitEventMt)
    end
})
