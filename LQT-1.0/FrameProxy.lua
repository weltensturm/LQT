---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT


local FrameProxy
local FrameProxyMt
local ApplyFrameProxy

local stringbyte = string.byte

local get_context = function()
    return strsplittable('\n', debugstack(3,0,1) or '')[1]
end


-- Sentinel magic
local CODE = {}
local CONTEXT = {}
local KEY = {}
local COMPILED = {}
local ARGS = {}
local PARENT = {}


local function mergeLists(t1, t2)
    if not t1 then
        return t2
    end
    local result = {}
    for i=1,#t1 do
        result[i] = t1[i]
    end
    local t1size = #t1
    for i=1,#t2 do
        result[t1size+i] = t2[i]
    end
    return result
end


local SLOT_BYTE = stringbyte('\v', 1)

local function slots(count)
    if count > 1 then
        return string.rep('\v, ', count)
    elseif count == 1 then
        return '\v'
    else
        return ''
    end
end


FrameProxyMt = {
    __call = function(proxy, selfMaybe, ...)
        if getmetatable(selfMaybe) == FrameProxyMt then
            local parent_code = rawget(rawget(proxy, PARENT), CODE)
            local key = rawget(proxy, KEY)
            local args = mergeLists(rawget(proxy, ARGS), { ... })
            return FrameProxy(
                parent_code .. ':' .. key .. '(' .. slots(#args) .. ')',
                args,
                get_context(),
                nil,
                proxy
            )
        else
            local args = { selfMaybe, ... }
            return FrameProxy(
                rawget(proxy, CODE) .. '({})',
                mergeLists(rawget(proxy, ARGS), args),
                get_context(),
                nil,
                proxy
            )
        end
    end,
    __index = function(self, attr)
        return FrameProxy(
            rawget(self, CODE) .. '.' .. attr,
            nil,
            get_context(),
            attr,
            self
        )
    end,
    __tostring = function(self)
        return rawget(self, CODE)
    end,
    __add = function(self, other)
        if getmetatable(other) == FrameProxyMt then
            return FrameProxy(
                '(' .. rawget(self, CODE) .. ' + ' .. rawget(other, CODE) .. ')',
                mergeLists(rawget(self, ARGS), rawget(other, ARGS)),
                get_context(),
                nil,
                self
            )
        else
            return FrameProxy(
                '(' .. rawget(self, CODE) .. ' + ' .. other .. ')',
                nil,
                get_context(),
                nil,
                self
            )
        end
    end,
    __sub = function(self, other)
        if getmetatable(other) == FrameProxyMt then
            return FrameProxy(
                '(' .. rawget(self, CODE) .. ' - ' .. rawget(other, CODE) .. ')',
                mergeLists(rawget(self, ARGS), rawget(other, ARGS)),
                get_context(),
                nil,
                self
            )
        else
            return FrameProxy(
                '(' .. rawget(self, CODE) .. ' - ' .. other .. ')',
                nil,
                get_context(),
                nil,
                self
            )
        end
    end,
    __mul = function(self, other)
        if getmetatable(other) == FrameProxyMt then
            return FrameProxy(
                '(' .. rawget(self, CODE) .. ' * ' .. rawget(other, CODE) .. ')',
                mergeLists(rawget(self, ARGS), rawget(other, ARGS)),
                get_context(),
                nil,
                self
            )
        else
            return FrameProxy(
                '(' .. rawget(self, CODE) .. ' * ' .. other .. ')',
                nil,
                get_context(),
                nil,
                self
            )
        end
    end,
    __div = function(self, other)
        if getmetatable(other) == FrameProxyMt then
            return FrameProxy(
                '(' .. rawget(self, CODE) .. ' / ' .. rawget(other, CODE) .. ')',
                mergeLists(rawget(self, ARGS), rawget(other, ARGS)),
                get_context(),
                nil,
                self
            )
        else
            return FrameProxy(
                '(' .. rawget(self, CODE) .. ' / ' .. other .. ')',
                nil,
                get_context(),
                nil,
                self
            )
        end
    end
}

---@return LQT.AnyWidget | table<string, any>
FrameProxy = function(code, args, context, key, parent)
    return setmetatable(
        {
            [CODE] = code or 'self',
            [ARGS] = args or parent and rawget(parent, ARGS),
            [CONTEXT] = context or get_context(),
            [KEY] = key,
            [PARENT] = parent,
        },
        FrameProxyMt
    )
end


local function CompileFrameProxy(proxy)
    local txt_orig = rawget(proxy, CODE)
    local arg_idx = 0
    local txt = txt_orig:gsub('\v', function()
        arg_idx = arg_idx + 1
        return 'args[' .. arg_idx .. ']'
    end)

    local file, line = rawget(proxy, CONTEXT):match('%[string "(@.*)"%]:(%d+).*')

    local fn = assert(
        loadstring(
            string.rep('\n', (line or 1)-1) ..
            'local args = ...; ' ..
            'return function(self) ' ..
                'return assert(' .. txt .. ', "' .. txt .. ' is nil") ' ..
            'end',
            (file or '@unknown') .. '<LQT>'
        )
    )
    rawset(proxy, COMPILED, fn(rawget(proxy, ARGS)))
    return rawget(proxy, COMPILED)
end


---@param frame LQT.AnyWidget
---@return LQT.AnyWidget target
---@return string attribute
local FrameProxyTargetKey = function(frame, proxy)
    local target = CompileFrameProxy(rawget(proxy, PARENT))(frame)
    return target, rawget(proxy, KEY)
end


local FrameProxyParentKey = function(proxy)
    local parent = CompileFrameProxy(rawget(proxy, PARENT))
    return parent, rawget(proxy, KEY)
end


local function IsFrameProxy(value)
    return type(value) == 'table' and getmetatable(value) == FrameProxyMt
end


LQT.CompileFrameProxy = CompileFrameProxy
LQT.FrameProxyTargetKey = FrameProxyTargetKey
LQT.FrameProxyParentKey = FrameProxyParentKey
LQT.FrameProxy = FrameProxy
LQT.FrameProxyMt = FrameProxyMt
LQT.IsFrameProxy = IsFrameProxy

---@type ScriptRegion|any
LQT.SELF = FrameProxy()

---@type ScriptRegion|any
LQT.PARENT = FrameProxy():GetParent()


--[[
local frame = CreateFrame('Frame', nil, UIParent)
frame:SetSize(20, 32)
assert(CompileFrameProxy(LQT.SELF)(frame) == frame)
assert(CompileFrameProxy(LQT.PARENT)(frame) == frame:GetParent())
assert(CompileFrameProxy(LQT.PARENT:GetName())(frame) == 'UIParent')
assert(CompileFrameProxy(LQT.SELF:GetWidth() + LQT.SELF:GetHeight())(frame) == frame:GetWidth() + frame:GetHeight())
]]
