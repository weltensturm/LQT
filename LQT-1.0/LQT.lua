---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT

local internal = LQT.internal
local chain_extend = internal.chain_extend


LQT.Style = chain_extend(nil, {})


LQT.Frame = LQT.Style
    .constructor(function(obj, globalName, ...) return CreateFrame('Frame', globalName, obj, ...) end)


LQT.Button = LQT.Style
    .constructor(function(obj, globalName, ...) return CreateFrame('Button', globalName, obj, ...) end)


LQT.ItemButton = LQT.Style
    .constructor(function(obj, globalName, ...) return CreateFrame('ItemButton', globalName, obj, ...) end)


LQT.CheckButton = LQT.Style
    .constructor(function(obj, globalName, ...) return CreateFrame('CheckButton', globalName, obj, ...) end)


LQT.Cooldown = LQT.Style
    .constructor(function(obj, globalName, ...) return CreateFrame('Cooldown', globalName, obj, 'CooldownFrameTemplate', ...) end)


LQT.StatusBar = LQT.Style
    .constructor(function(obj, globalName, ...) return CreateFrame('StatusBar', globalName, obj, ...) end)


LQT.Texture = LQT.Style
    .constructor(function(obj, ...) return obj:CreateTexture(...) end)


LQT.FontString = LQT.Style
    .constructor(function(obj, ...) return obj:CreateFontString(...) end)


LQT.MaskTexture = LQT.Style
    .constructor(function(obj, ...) return obj:CreateMaskTexture(...) end)


LQT.EditBox = LQT.Style
    .constructor(function(obj, globalName, ...) return CreateFrame('EditBox', globalName, obj, ...) end)


LQT.ScrollFrame = LQT.Style
    .constructor(function(obj, globalName, ...) return CreateFrame('ScrollFrame', globalName, obj, ...) end)


LQT.AnimationGroup = LQT.Style
    .constructor(function(obj, ...) return obj:CreateAnimationGroup(...) end)


LQT.Animation = {
    Alpha           = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Alpha', ...) end),
    Rotation        = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Rotation', ...) end),
    Translation     = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Translation', ...) end),
    Scale           = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Scale', ...) end),
    LineScale       = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('LineScale', ...) end),
    LineTranslation = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('LineTranslation', ...) end),
    FlipBook        = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('FlipBook', ...) end),
    Path            = LQT.Style.constructor(function(obj, ...) return obj:CreateAnimation('Path', ...) end),
}

