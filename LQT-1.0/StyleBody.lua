local ADDON, Addon = ...


---@class LQT
local LQT = Addon.LQT

---@class LQT.internal
local internal = LQT.internal

local IsStyle = LQT.internal.IsStyle
local IsFrameProxy = LQT.IsFrameProxy
local FrameProxyTargetKey = LQT.FrameProxyTargetKey
local ApplyFrameProxy = LQT.ApplyFrameProxy
local run_head = LQT.internal.run_head

local ACTION = LQT.internal.FIELDS.ACTION
local ARGS = LQT.internal.FIELDS.ARGS
local CONSTRUCTOR = LQT.internal.FIELDS.CONSTRUCTOR
local CONTEXT = LQT.internal.FIELDS.CONTEXT
local COMPILED = LQT.internal.FIELDS.COMPILED
local BOUND_FRAME = LQT.internal.FIELDS.BOUND_FRAME
local CLASS = LQT.internal.FIELDS.CLASS

local chain_extend = LQT.internal.chain_extend
local get_context = LQT.internal.get_context



local function ShallowCopy(table)
    local t = {}
    for k, v in pairs(table) do
        t[k] = v
    end
    return t
end


local COMPILED_FN_ENV = LQT.internal.COMPILED_FN_ENV


local CompilerMT = {
    __index = {
        append = function(self, ...)
            local arglength = select('#', ...)
            local code = select(arglength, ...)
            if self[3] then
                for k, v in pairs(self[3]) do
                    code = code:gsub('{' .. k .. '}', v)
                end
            end
            for i=1, arglength-1 do
                local var = select(i, ...)
                if type(var) == 'number' and not tostring(var):find('%a') then
                    code = code:gsub('{' .. i .. '}', var)
                elseif type(var) == 'string' then
                    code = code:gsub('{' .. i .. '}', ' [==[' .. var .. ']==]')
                elseif type(var) == 'nil' then
                    assert(false, 'Argument ' .. i .. ' is nil')
                else
                    code = code:gsub('{' .. i .. '}', 'args[' .. #self[2]+1 .. ']')
                    self[2][#self[2]+1] = var
                end
            end
            self[1] = self[1] .. code .. ';\n'
        end,
        static = function(self, static)
            self[3] = static
        end,
        compile = function(self, context)
            local fn, error = loadstring(self[1], context)

            -- if not fn then
            --     local lineno = error --[[@as string]]:match('(%d+): ')
            --     local l = 0
            --     for line in self[1]:gmatch('(.-)\n') do
            --         l = l + 1
            --         if l == lineno then
            --             assert(false, error .. ': ' .. line)
            --         end
            --     end
            -- end
            -- local function onError(msg)
            --     local lineno = tonumber(msg:match('(%d+): '))
            --     local l = 0
            --     for line in self[1]:gmatch('(.-)\n') do
            --         l = l + 1
            --         if l == lineno then
            --             CallErrorHandler(msg .. ': ' .. line)
            --             return
            --         end
            --     end
            -- end
            -- local fn2 = function(...)
            --     return select(2, xpcall(fn --[[@as function]], onError, ...))
            -- end

            return
                assert(fn, error),
                self[2]
        end
    }
}

local function Compiler()
    return setmetatable({'', {}}, CompilerMT)
end


local function CompileBody(parentClass, arg, context)

    local attributes = {}
    local childrenCreate = {}
    local children = {}
    local preInitialize = {}
    local initialize = {}

    local class = ShallowCopy(parentClass or {})

    for key, value in pairs(arg) do

        if type(key) == 'number' then
            if IsStyle(value) then
                internal.CompileChain(value)
                table.insert(children, { nil, value })
            else
                table.insert(initialize, { nil, value })
            end

        elseif IsFrameProxy(key) then
            if value then
                table.insert(preInitialize, { key, value })
            end

        elseif type(key) == 'table' and getmetatable(key).lqtKeyCompile then
            if value then
                table.insert(preInitialize, getmetatable(key).lqtKeyCompile(key, value))
            end

        elseif type(value) == 'table' then
            if IsFrameProxy(value) then
                assert(not class[key], 'Cannot shadow ' .. key .. ' of parent class')
                class[key] = value
                if type(key) == 'string' then
                    table.insert(attributes, { key, value })
                else
                    table.insert(initialize, { key, value })
                end

            elseif IsStyle(value) then
                internal.CompileChain(value)
                if type(key) == 'string' then
                    if key:sub(1, 1) ~= '.' then
                        assert(value[CONSTRUCTOR], 'Style has no constructor: ' .. value[CONTEXT])
                        assert(not class[key], 'Cannot shadow ' .. key .. ' of parent class')
                        class[key] = value
                        table.insert(childrenCreate, { key, value })
                    end
                    table.insert(children, { key, value })
                else
                    assert(false, 'Not implemented: ' .. type(key) .. ' ' .. tostring(key))
                end

            else
                assert(not class[key], 'Cannot shadow ' .. key .. ' of parent class')
                class[key] = value
                table.insert(attributes, { key, value })
            end
        else
            assert(not class[key], 'Cannot shadow ' .. key .. ' of parent class')
            class[key] = value
            table.insert(attributes, { key, value })
        end
    end

    table.sort(childrenCreate, function(a, b)
        return a[2][CONTEXT] < b[2][CONTEXT]
    end)

    table.sort(children, function(a, b)
        return a[2][CONTEXT] < b[2][CONTEXT]
    end)

    local code = Compiler()
    code:static {
        env = COMPILED_FN_ENV
    }

    code:append('-- ' .. context)
    code:append('local widget, parent_if_constructed, args, {env} = ...')

    for i=1, #attributes do
        local k, v = attributes[i][1], attributes[i][2]
        if IsFrameProxy(v) then
            code:append(k, v, [[
                if not widget[{1}] then
                    widget[{1}] = ApplyFrameProxy(widget, {2})
                end
            ]])
        elseif type(v) == 'table' and not next(v) and not getmetatable(v) then
            code:append(k, 'widget[{1}] = {}')
        else
            code:append(k, v, 'widget[{1}] = {2}')
        end
    end

    for i=1, #childrenCreate do
        local k, v = childrenCreate[i][1], childrenCreate[i][2]
        code:append(k, v[CONSTRUCTOR], v[CLASS], [[
            if not widget[{1}] then
                widget[{1}] = {2}(widget)
                widget[{1}]['lqt.class'] = {3}
            end
        ]])
    end

    for i=1, #children do
        local k, v = children[i][1], children[i][2]
        if k and k:sub(1, 1) == '.' then
            code:append(k, v[COMPILED], [[
                local StyleChildren = {2}[1]
                for child in query(widget, {1}) do
                    StyleChildren(child, widget, {2}[2], {env})
                end
            ]])
        elseif k then
            code:append(k, v[COMPILED], [[
                local StyleChild = {2}[1]
                StyleChild(widget[{1}], widget, {2}[2], {env})
            ]])
        else
            code:append(v[COMPILED][1], v[COMPILED][2], [[
                local Style = {1}
                Style(widget, parent_if_constructed, {2}, {env})
            ]])
        end
    end

    for i=1, #preInitialize do
        if type(preInitialize[i]) == 'table' and IsFrameProxy(preInitialize[i][1]) then
            local proxy, fn = preInitialize[i][1], preInitialize[i][2]
            code:append(proxy, fn, FrameProxyTargetKey, [[
                local proxyTarget, proxyKey = {3}(widget, {1})
                assert(proxyKey, 'Cannot hook ' .. tostring(proxy))
                if widget == proxyTarget then
                    hooksecurefunc(widget, proxyKey, {2})
                else
                    hooksecurefunc(proxyTarget, proxyKey, function(...)
                        {2}(widget, ...)
                    end)
                end
            ]])
        else
            code:append(preInitialize[i], '{1}(widget, parent_if_constructed)')
        end
    end

    for i=1, #initialize do
        local k, v = initialize[i][1], initialize[i][2]
        if type(v) == 'function' then
            code:append(v, '{1}(widget, parent_if_constructed)')
        elseif k and IsFrameProxy(v) then
            code:append(k, v, 'widget[{1}] = ApplyFrameProxy(widget, {2})')
        else
            assert(false, 'Not implemented')
        end
    end

    local codeCount = 1
    while class['__code_' .. codeCount] do
        codeCount = codeCount + 1
    end
    class['__code_' .. codeCount] = code[1]

    local fn, args = code:compile(context:gsub('%[string "(@.*)"%]:(%d+).*', '%1:%2') .. ':{}')

    return fn, args, class
end



function internal.CompileBody(style, arg, context)
    if type(arg) ~= 'table' then
        error('Cannot call CompileBody with ' .. type(arg))
    end
    context = context or get_context(4)
    local compiled, compiledargs, class = CompileBody(style[CLASS], arg, context)
    local action = chain_extend(style, { [ACTION]=compiled, [ARGS]=compiledargs, [CONTEXT]=context, [CLASS]=class })
    if action[BOUND_FRAME] then
        run_head(action)
    end
    return action
end
