---@class Addon
local Addon = select(2, ...)

---@class Addon.util
Addon.util = {}
---@class Addon.util
local util = Addon.util



function util.split_at_find(str, pattern, after)
    after = after or 0
    local i = string.find(str, pattern)
    if i then
        return strsub(str, 1, i+after-1), strsub(str, i+after)
    end
    return str, ''
end
