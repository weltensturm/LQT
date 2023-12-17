---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT


local FrameProxy
local FrameProxyMt
local ApplyFrameProxy


local get_context = function()
    return strsplittable('\n', debugstack(3,0,1))[1]
end


local FN = '__FrameProxy_fn'
local CONTEXT = '__FrameProxy_context'
local TEXT =  '__FrameProxy_text'
local KEY =  '__FrameProxy_key'


FrameProxyMt = {
    __call = function(proxy, selfMaybe, ...)
        if getmetatable(selfMaybe) == FrameProxyMt then
            local fn = rawget(proxy, FN)
            local args = { ... }
            return FrameProxy(
                function(root)
                    local result, frame = fn(root)
                    assert(result ~= nil, rawget(proxy, CONTEXT) .. rawget(proxy, TEXT) .. ' is nil')
                    return result(frame, unpack(args))
                end,
                get_context(),
                rawget(proxy, TEXT) .. '(self, ...)'
            )
        else
            local fn = rawget(proxy, FN)
            local args = { selfMaybe, ... }
            return FrameProxy(
                function(root)
                    local result = fn(root)
                    assert(result ~= nil, rawget(proxy, CONTEXT) .. ' ' .. rawget(proxy, TEXT) .. ' is nil')
                    return result(unpack(args))
                end,
                get_context(),
                rawget(proxy, TEXT) .. '(...)'
            )
        end
    end,
    __index = function(self, attr)
        if
            attr == CONTEXT
            or attr == FN
            or attr == TEXT
            or attr == KEY
        then
            return rawget(self, attr)
        end
        local fn = rawget(self, FN)
        return FrameProxy(
            function(root)
                local result = fn(root)
                assert(result ~= nil, rawget(self, CONTEXT) .. ' ' .. rawget(self, TEXT) .. ' is nil')
                return result[attr], result
            end,
            get_context(),
            rawget(self, TEXT) .. '.' .. attr,
            attr
        )
    end,
    __tostring = function(self)
        return rawget(self, TEXT)
    end,
    __add = function(self, num)
        local fn = rawget(self, FN)
        if getmetatable(num) == FrameProxyMt then
            return FrameProxy(
                function(root)
                    return fn(root) + ApplyFrameProxy(root, num)
                end,
                get_context(),
                rawget(self, TEXT) .. ' + ' .. tostring(num)
            )
        else
            return FrameProxy(
                function(root)
                    return fn(root) + num
                end,
                get_context(),
                rawget(self, TEXT) .. ' + ' .. num
            )
        end
    end,
    __sub = function(self, num)
        local fn = rawget(self, FN)
        if getmetatable(num) == FrameProxyMt then
            return FrameProxy(
                function(root)
                    return fn(root) - ApplyFrameProxy(root, num)
                end,
                get_context(),
                rawget(self, TEXT) .. ' - ' .. tostring(num)
            )
        else
            return FrameProxy(
                function(root)
                    return fn(root) - num
                end,
                get_context(),
                rawget(self, TEXT) .. ' - ' .. num
            )
        end
    end,
    __mul = function(self, num)
        local fn = rawget(self, FN)
        if getmetatable(num) == FrameProxyMt then
            return FrameProxy(
                function(root)
                    return fn(root) * ApplyFrameProxy(root, num)
                end,
                get_context(),
                rawget(self, TEXT) .. ' * ' .. tostring(num)
            )
        else
            return FrameProxy(
                function(root)
                    return fn(root) * num
                end,
                get_context(),
                rawget(self, TEXT) .. ' * ' .. num
            )
        end
    end,
    __div = function(self, num)
        local fn = rawget(self, FN)
        if getmetatable(num) == FrameProxyMt then
            return FrameProxy(
                function(root)
                    return fn(root) / ApplyFrameProxy(root, num)
                end,
                get_context(),
                rawget(self, TEXT) .. ' / ' .. tostring(num)
            )
        else
            return FrameProxy(
                function(root)
                    return fn(root) / num
                end,
                get_context(),
                rawget(self, TEXT) .. ' / ' .. num
            )
        end
    end
}

---@return LQT.AnyWidget | table<string, any>
FrameProxy = function(fn, context, text, key)
    return setmetatable(
        {
            [FN] = fn or function(root) return root end,
            [CONTEXT] = context or get_context(),
            [TEXT] = text or 'self',
            [KEY] = key
        },
        FrameProxyMt
    )
end

ApplyFrameProxy = function(frame, proxy)
    local result, _ = rawget(proxy, FN)(frame, frame)
    return assert(result, rawget(proxy, TEXT) .. ' is nil')
end

---@param frame LQT.AnyWidget
---@return LQT.AnyWidget target
---@return string attribute
local FrameProxyTargetKey = function(frame, proxy)
    local result, target = rawget(proxy, FN)(frame, frame)
    assert(result, rawget(proxy, TEXT) .. ' is nil')
    return target, rawget(proxy, KEY)
end


local function IsFrameProxy(value)
    return type(value) == 'table' and getmetatable(value) == FrameProxyMt
end


LQT.ApplyFrameProxy = ApplyFrameProxy
LQT.FrameProxyTargetKey = FrameProxyTargetKey
LQT.FrameProxy = FrameProxy
LQT.FrameProxyMt = FrameProxyMt
LQT.IsFrameProxy = IsFrameProxy

---@type any
LQT.SELF = FrameProxy()

---@type any
LQT.PARENT = FrameProxy():GetParent()


--[[#

local frame = CreateFrame('Frame', nil, UIParent)
frame:SetSize(20, 32)
assert(ApplyFrameProxy(frame, LQT.PARENT) == frame:GetParent())
assert(ApplyFrameProxy(frame, LQT.PARENT:GetName()) == 'UIParent')
assert(ApplyFrameProxy(frame, LQT.SELF:GetWidth() + LQT.SELF:GetHeight()) == 52)

--]]
