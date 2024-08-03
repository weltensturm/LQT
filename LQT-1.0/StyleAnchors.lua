---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT

---@class LQT.internal.StyleAttributes
local StyleAttributes = LQT.internal.StyleAttributes

local chain_extend = LQT.internal.chain_extend

local FIELDS = LQT.internal.FIELDS
local CLEARS_POINTS = FIELDS.CLEARS_POINTS

local AnchorMt = {}

function AnchorMt:__index(attr)
    local point, style = self[1], self[2]
    return function(self1, target, x, y)
        assert(self == self1, 'Cannot call .' .. attr .. ', use :' .. attr)
        if not style[CLEARS_POINTS] then
            style = chain_extend(style, { [CLEARS_POINTS]=true })
                :ClearAllPoints()
        end
        if type(target) ~= 'table' then
            y = x
            x = target
            target = LQT.PARENT
        end
        return style:Point(point, target, attr, x, y)
    end
end

function AnchorMt:__call(target, x, y)
    local point, style = self[1], self[2]
    if not style[CLEARS_POINTS] then
        style = chain_extend(style, { [CLEARS_POINTS]=true })
            :ClearAllPoints()
    end
    if type(target) ~= 'table' then
        y = x
        x = target
        target = LQT.PARENT
    end
    return style:Point(point, target, point, x, y)
end


---@class LQT.AnchorTarget
---@overload fun(self: LQT.internal.Anchor): LQT.StyleChain
---@overload fun(self: LQT.internal.Anchor, x: number, y: number): LQT.StyleChain
---@overload fun(self: LQT.internal.Anchor, target: FrameScriptObject): LQT.StyleChain
---@overload fun(self: LQT.internal.Anchor, target: FrameScriptObject, x: number, y: number): LQT.StyleChain


---@class LQT.internal.Anchor
---@field TOP LQT.AnchorTarget
---@field TOPRIGHT LQT.AnchorTarget
---@field RIGHT LQT.AnchorTarget
---@field BOTTOMRIGHT LQT.AnchorTarget
---@field BOTTOM LQT.AnchorTarget
---@field BOTTOMLEFT LQT.AnchorTarget
---@field LEFT LQT.AnchorTarget
---@field TOPLEFT LQT.AnchorTarget
---@field CENTER LQT.AnchorTarget


---@class LQT.internal.StyleAttributes
---@field TOP LQT.internal.Anchor|LQT.AnchorTarget
---@field TOPRIGHT LQT.internal.Anchor|LQT.AnchorTarget
---@field RIGHT LQT.internal.Anchor|LQT.AnchorTarget
---@field BOTTOMRIGHT LQT.internal.Anchor|LQT.AnchorTarget
---@field BOTTOM LQT.internal.Anchor|LQT.AnchorTarget
---@field BOTTOMLEFT LQT.internal.Anchor|LQT.AnchorTarget
---@field LEFT LQT.internal.Anchor|LQT.AnchorTarget
---@field TOPLEFT LQT.internal.Anchor|LQT.AnchorTarget
---@field CENTER LQT.internal.Anchor|LQT.AnchorTarget


function StyleAttributes:TOP() return setmetatable({ 'TOP', self }, AnchorMt) end
function StyleAttributes:TOPRIGHT() return setmetatable({ 'TOPRIGHT', self }, AnchorMt) end
function StyleAttributes:RIGHT() return setmetatable({ 'RIGHT', self }, AnchorMt) end
function StyleAttributes:BOTTOMRIGHT() return setmetatable({ 'BOTTOMRIGHT', self }, AnchorMt) end
function StyleAttributes:BOTTOM() return setmetatable({ 'BOTTOM', self }, AnchorMt) end
function StyleAttributes:BOTTOMLEFT() return setmetatable({ 'BOTTOMLEFT', self }, AnchorMt) end
function StyleAttributes:LEFT() return setmetatable({ 'LEFT', self }, AnchorMt) end
function StyleAttributes:TOPLEFT() return setmetatable({ 'TOPLEFT', self }, AnchorMt) end
function StyleAttributes:CENTER() return setmetatable({ 'CENTER', self }, AnchorMt) end


