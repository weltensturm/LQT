---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT

---@class LQT.internal
local internal = {}
LQT.internal = internal

local ApplyFrameProxy = LQT.ApplyFrameProxy


--[[ there is a lot of cross referencing between Style*.lua so this has to exist ]]

---@class LQT.internal.StyleFunctions
internal.StyleFunctions  = {}

---@class LQT.internal.StyleAttributes
internal.StyleAttributes = {}


internal.StyleChainMeta = {}
local StyleChainMeta = internal.StyleChainMeta


internal.COMPILED_FN_ENV = 'ApplyFrameProxy, query, FrameExtensions'


function internal.IsStyle(value)
    return type(value) == 'table' and getmetatable(value) == StyleChainMeta
end


function internal.get_context(level)
    local context = strsplittable('\n', debugstack(level or 3, 99, 99))
    for i=1, #context do
        if context[i] ~= '[string "=(tail call)"]: ?' then
            return context[i]
        end
    end
end
local get_context = internal.get_context


local NOOP = 1
local FN = 2
local DERIVESTYLE = 3


local PARENT = 1
local ACTION = 2
local ARGS = 3
local CONSTRUCTOR = 4
local BOUND_FRAME = 5
local FILTER = 6
local COMPILED = 7
local CONTEXT = 8
local CLEARS_POINTS = 9
local CLASS = 10


internal.ACTIONS = {
    NOOP = NOOP,
    FN = FN,
    DERIVESTYLE = DERIVESTYLE,
}


---@enum LQT.internal.FIELDS
internal.FIELDS = {
    PARENT = PARENT,
    ACTION = ACTION,
    ARGS = ARGS,
    CONSTRUCTOR = CONSTRUCTOR,
    BOUND_FRAME = BOUND_FRAME,
    FILTER = FILTER,
    COMPILED = COMPILED,
    CONTEXT = CONTEXT,
    CLEARS_POINTS = CLEARS_POINTS,
    CLASS = CLASS
}

internal.ops = {
    [NOOP] = function() end,
    [FN] = function(object, fn)
        fn(object)
    end,
}

local ops = internal.ops


---@param action LQT.StyleChain
---@param object ScriptObject?
---@param constructed ScriptObject | nil
function internal.run_head(action, object, constructed)
    if type(action[ACTION]) == 'function' then
        action[ACTION](object or action[BOUND_FRAME], constructed, action[ARGS], ApplyFrameProxy, LQT.query, LQT.FrameExtensions)
    else
        ops[action[ACTION]](object or action[BOUND_FRAME], action[ARGS], constructed)
    end
end


function internal.chain_extend(parent, new)
    local action = {
        [PARENT]       = parent or false,
        [ACTION]       = new[ACTION]       or NOOP,
        [ARGS]         = new[ARGS]         or {},
        [CONSTRUCTOR]  = new[CONSTRUCTOR]  or parent and parent[CONSTRUCTOR] or false,
        [BOUND_FRAME]  = new[BOUND_FRAME]  or parent and parent[BOUND_FRAME] or false,
        [FILTER]       = new[FILTER] and (parent and parent[FILTER] and function(obj) return parent[FILTER](obj) and new[FILTER](obj) end
                                                                     or new[FILTER])
                                      or parent and parent[FILTER]
                                      or false,
        [COMPILED] = false,
        [CONTEXT] = new[CONTEXT] or get_context(4),
        [CLEARS_POINTS] = new[CLEARS_POINTS] or parent and parent[CLEARS_POINTS] or false,
        [CLASS] = new[CLASS] or parent and parent[CLASS] or false
    }
    setmetatable(action, StyleChainMeta)
    return action
end

