local ADDON, Addon = ...

---@class LQT
local LQT = Addon.LQT

local internal = LQT.internal
local StyleAttributes = internal.StyleAttributes
local StyleFunctions = internal.StyleFunctions
local StyleChainMeta = internal.StyleChainMeta
local chain_extend = internal.chain_extend


local ACTIONS = internal.ACTIONS
local FIELDS = internal.FIELDS
local get_context = internal.get_context


local FrameProxyMt = LQT.FrameProxyMt
local CompileFrameProxy = LQT.CompileFrameProxy


local FN = ACTIONS.FN

local ACTION = FIELDS.ACTION
local ARGS = FIELDS.ARGS
local CONTEXT = FIELDS.CONTEXT


local function CompileMethodCallText(attr, ...)
    local args = { ... }

    local argsOut = ''
    local nextArg = 1

    for i=1, #args do
        local comma = nextArg > 1 and ', ' or ''
        if getmetatable(args[i]) == FrameProxyMt then
            args[i] = CompileFrameProxy(args[i])
            argsOut = argsOut .. comma .. 'args[{i}][' .. nextArg .. '](self)'
        else
            argsOut = argsOut .. comma .. 'args[{i}][' .. nextArg .. ']'
        end
        nextArg = nextArg + 1
    end

    local code =
        'if self.Set' .. attr .. ' then ' ..
            'self:Set' .. attr .. '(' .. argsOut .. ') ' ..
        'else ' ..
            'self:' .. attr .. '(' .. argsOut .. ') ' ..
        'end\n'

    return code, args
end


function StyleChainMeta:__index(attr)
    if type(attr) == 'number' then
        return rawget(self, attr)
    elseif StyleAttributes[attr] then
        return StyleAttributes[attr](self)
    else
        return function(arg1, ...)
            if arg1 == self then -- called with :
                -- local context = get_context():gsub('%[string "(@.*)"%]:(%d+).*', '%1<LQT>:%2')
                local code, args = CompileMethodCallText(attr, ...)
                return chain_extend(self, { [ACTION]=code, [ARGS]=args, [CONTEXT]=get_context() })
            else -- called with .
                return StyleFunctions[attr](self, arg1, ...)
            end
        end
    end
end


function StyleChainMeta:__call(...)
    assert(select('#', ...) == 1)
    local arg = assert(select(1, ...), 'Style: cannot call with nil: ' .. get_context())
    if type(arg) == 'table' then
        if arg.GetObjectType then
            StyleFunctions.apply(self, arg)
            return nil
        else
            return internal.CompileBody(self, arg, get_context())
        end
    elseif type(arg) == 'function' then
        return chain_extend(self, { [ACTION]=FN, [ARGS]=arg })
    end
    assert(false, 'Style: cannot call with ' .. type(arg) .. ': ' .. get_context())
end

