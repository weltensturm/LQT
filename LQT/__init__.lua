---@class Addon
local Addon = select(2, ...)
local ADDON = select(1, ...)

---@class LQT
Addon.LQT = {
    ---@class LQT.internal
    internal = {
        LQT_VERSION = 1,
        LQT_SOURCE = ADDON,
    }
}
