---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT
local query = LQT.query
local FrameExtensions = LQT.FrameExtensions
local ApplyFrameProxy = LQT.ApplyFrameProxy

---@class LQT.internal
local internal = LQT.internal

---@class LQT.internal.StyleFunctions
local StyleFunctions = internal.StyleFunctions

local chain_extend = internal.chain_extend
local get_context = internal.get_context
local run_head = internal.run_head

local ACTIONS = internal.ACTIONS
local FIELDS = internal.FIELDS

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

local IsStyle = internal.IsStyle


local COMPILED_FN_ENV = LQT.internal.COMPILED_FN_ENV


local debugDepth = 0


local function CompileChain(style)
    local compiled = style[COMPILED]
    if compiled then
        return compiled[1], compiled[2]
    end
    local time = debugprofilestop()

    local parent = style

    local code = ''
    local arg = 1
    local args = {}

    while parent do
        if parent[ACTION] ~= NOOP then
            if parent[ACTION] == DERIVESTYLE then
                code = ('local inherit = args[' .. arg .. '][1]\n' ..
                        'inherit(frame, parent_if_constructed, args[' .. arg .. '][2], {env})\n')
                    :gsub('{env}', COMPILED_FN_ENV)
                    .. code
                CompileChain(parent[ARGS])
                args[#args+1] = parent[ARGS][COMPILED]
            elseif parent[ACTION] == FN then
                code = 'args[' .. arg .. '](frame)\n' .. code
                args[#args+1] = parent[ARGS]
            elseif type(parent[ACTION]) == 'function' then
                code = ('local apply=args[{i}][1]; apply(frame, parent_if_constructed, args[{i}][2], {env})\n')
                    :gsub('{i}', arg)
                    :gsub('{env}', COMPILED_FN_ENV)
                    .. code
                args[#args+1] = { parent[ACTION], parent[ARGS] }
            else
                assert(false, code .. ' ' .. tostring(parent[CONTEXT]))
            end
            arg = arg + 1
        end
        parent = parent[PARENT]
    end

    code = ('local frame, parent_if_constructed, args, {env} = ...\n')
        :gsub('{env}', COMPILED_FN_ENV)
        .. code

    local fn = loadstring(code, style[CONTEXT]:gsub('%[string "(@.*)"%]:(%d+).*', '%1:%2') .. ':[apply]')
    style[COMPILED] = { fn, args }

    time = (debugprofilestop() - time)
    if time > 1 then
        print(string.format('c%s%.2f', string.rep('/', debugDepth), time), style[CONTEXT])
    end

    return fn, args
end

internal.CompileChain = CompileChain


function StyleFunctions:apply(frame, parent_if_constructed)
    local time = debugprofilestop()
    frame = frame or self[BOUND_FRAME]
    local filter = self[FILTER]
    local apply, compiledargs = CompileChain(self)
    local time_compiled = debugprofilestop() - time

    debugDepth = debugDepth + 1

    if not filter or filter(frame) then
        apply(frame, parent_if_constructed, compiledargs, ApplyFrameProxy, query, FrameExtensions)
    end

    debugDepth = debugDepth - 1

    time = (debugprofilestop() - time)
    if time > 1 then
        print(string.format('%s%.2f %.2f', string.rep('/', debugDepth), time, time_compiled), self[CONTEXT])
    end
    return self
end


function StyleFunctions:constructor(fn)
    if self[CONSTRUCTOR] then
        local old = self[CONSTRUCTOR]
        local new = function(...)
            fn(old, ...)
        end
        return chain_extend(self, { [CONSTRUCTOR]=new })
    else
        return chain_extend(self, { [CONSTRUCTOR]=fn })
    end
end


function StyleFunctions:new(parent, ...)
    local obj = self[CONSTRUCTOR](parent or UIParent, ...)
    local new, compiledargs = CompileChain(self)
    new(obj, parent or UIParent, compiledargs, ApplyFrameProxy, query, FrameExtensions)
    -- self.apply(obj, parent or UIParent)
    return obj
end


function StyleFunctions:filter(filter)
    return chain_extend(self, { [FILTER]=filter })
end

