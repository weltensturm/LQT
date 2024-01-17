local ADDON = select(1, ...)

---@class Addon
local Addon = select(2, ...)

assert(ADDON == 'LQT-1.0', 'Remove this entire file if you embed LQT')

---@class LQT
Addon.LQT = {}
_G['LQT-1.0'] = Addon.LQT
