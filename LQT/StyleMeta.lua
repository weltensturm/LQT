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
local run_head = internal.run_head
local get_context = internal.get_context


local FrameProxyMt = LQT.FrameProxyMt
local FrameExtensions = LQT.FrameExtensions


local NOOP = ACTIONS.NOOP
local FN = ACTIONS.FN
local DERIVESTYLE = ACTIONS.DERIVESTYLE


local PARENT = FIELDS.PARENT
local ACTION = FIELDS.ACTION
local ARGS = FIELDS.ARGS
local CONSTRUCTOR = FIELDS.CONSTRUCTOR
local BOUND_FRAME = FIELDS.BOUND_FRAME
local FILTER = FIELDS.FILTER
local COMPILED = FIELDS.COMPILED
local CONTEXT = FIELDS.CONTEXT
local CLEARS_POINTS = FIELDS.CLEARS_POINTS
local CLASS = FIELDS.CLASS


local function isWithContext(name, set)
    name = set and name or 'Set' .. name
    return
        name == 'SetHooks'
        or name == 'SetEvents'
        or name == 'SetEventHooks'
end


local function CompileMethodCall(attr, context, ...)

    local args = { ... }

    local argsOut = ''
    local nextArg = 1

    if isWithContext(attr) then
        table.insert(args, context)
    end

    for i=1, #args do
        local comma = nextArg > 1 and ', ' or ''
        if getmetatable(args[i]) == FrameProxyMt then
            argsOut = argsOut .. comma .. 'ApplyFrameProxy(self, args[' .. nextArg .. '])'
        else
            argsOut = argsOut .. comma .. 'args[' .. nextArg .. ']'
        end
        nextArg = nextArg + 1
    end

    local callmethod_text
    if FrameExtensions[attr] then
        callmethod_text = [[
            local self, _, args, ApplyFrameProxy, _, FrameExtensions = ...
            if self.Set{Fn} then
                self:Set{Fn}({argsOut})
            elseif self.{Fn} then
                self:{Fn}({argsOut})
            else
                FrameExtensions.{Fn}(self{argsOutComma})
            end
        ]]
    else
        callmethod_text = [[
            local self, _, args, ApplyFrameProxy, _, FrameExtensions = ...
            if self.Set{Fn} then
                self:Set{Fn}({argsOut})
            else
                self:{Fn}({argsOut})
            end
        ]]
    end
    local compiled = assert(
        loadstring(
            callmethod_text
                :gsub('{Fn}', attr)
                :gsub('{argsOut}', argsOut)
                :gsub('{argsOutComma}', (#args > 0 and ', ' or '') .. argsOut),
            context .. ':' .. attr
        )
    )
    return compiled, args

end


function StyleChainMeta:__index(attr)
    if type(attr) == 'number' then
        return rawget(self, attr)
    elseif StyleAttributes[attr] then
        return StyleAttributes[attr](self)
    else
        return function(arg1, ...)
            if arg1 == self then -- called with :
                local context = get_context():gsub('%[string "(@.*)"%]:(%d+).*', '%1:%2')
                local callmethod, args = CompileMethodCall(attr, context, ...)
                local action = chain_extend(self, { [ACTION]=callmethod, [ARGS]=args, [CONTEXT]=context })
                if action[BOUND_FRAME] then
                    run_head(action)
                end
                return action
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
            return chain_extend(self, { [BOUND_FRAME]=arg })
        else
            local action = internal.CompileBody(self, arg, get_context())
            return action
        end
    elseif type(arg) == 'function' then
        local action = chain_extend(self, { [ACTION]=FN, [ARGS]=arg })
        if action[BOUND_FRAME] then
            run_head(action)
        end
        return action
    end
    assert(false, 'Style: cannot call with ' .. type(arg) .. ': ' .. get_context())
end


local function JoinClasses(...)
    local res = {}
    for i=1, select('#', ...) do
        for k, v in pairs(select(i, ...)) do
            assert(not res[k], 'Duplicate key ' .. k)
            res[k] = v
        end
    end
    return res
end


function StyleChainMeta:__concat(arg)
    if type(arg) == 'table' then
        local class
        if self[CLASS] and arg[CLASS] then
            class = JoinClasses(self[CLASS], arg[CLASS])
        else
            class = self[CLASS] or arg[CLASS]
        end
        local action = chain_extend(self, {
                [ACTION]=DERIVESTYLE,
                [ARGS]=arg,
                [CLASS]=class,
                [CONSTRUCTOR]=self[CONSTRUCTOR] or arg[CONSTRUCTOR],
                [CONTEXT]=arg[CONTEXT]
            })
        if action[BOUND_FRAME] then
            run_head(action)
        end
        return action
    elseif type(arg) == 'function' then
        local action = chain_extend(self, { [ACTION]=FN, [ARGS]=arg })
        if action[BOUND_FRAME] then
            run_head(action)
        end
        return action
    end
    assert(false, 'Style: cannot concat ' .. type(arg))
end

