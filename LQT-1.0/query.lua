---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT


local function split_at_find(str, pattern, after)
    after = after or 0
    local i = string.find(str, pattern)
    if i then
        return strsub(str, 1, i+after-1), strsub(str, i+after)
    end
    return str, ''
end


local function ForTuple(fn, ...)
    for i=1, select('#', ...) do
        fn(select(i, ...))
    end
end


local function IsIdentifierName(str)
    return str:match('^[_%a][_%w]+$')
end


local function matches(obj, selector, parent)
    if selector == '*' then
        return true
    elseif parent and parent[selector] == obj then
        return true
    elseif selector:find(':') then
        local found = true
        for part in selector:gmatch('%s*([^:]+)') do
            found = found and matches(obj, part, parent)
        end
        return found
    else
        selector = '^' .. selector:gsub("%*", ".*"):gsub("#", "%%d+") .. '$'
        local name = obj:GetName()
        local attr_name = nil
        for k, v in pairs(parent or {}) do
            if v == obj then
                attr_name = k
                break
            end
        end
        return
            selector == '^NOATTR$' and (not attr_name or #attr_name == 0) or
            selector == '^NONAME$' and not name or
            attr_name and string.match(attr_name, selector) or
            string.match(obj:GetObjectType(), selector) or
            name and string.match(name, selector)
    end
end


local function parent_anchor_value(t, obj, anchoridx)
    if anchoridx[obj] then
        return anchoridx[obj]
    end
    if not pcall(function()
        local from, toF, to, x, y = obj:GetPoint()
        if not t[toF] then
            anchoridx[obj] = { 0, obj:GetTop() or 0, obj:GetLeft() or 0 }
            return
        end
        local i = parent_anchor_value(t, toF, anchoridx)[1]+1
        anchoridx[obj] = { i, obj:GetTop() or 0, obj:GetLeft() or 0 }
    end) then
        anchoridx[obj] = { 0, 100000, 100000 }
    end
    return anchoridx[obj]
end


local function sortByAnchors(t)
    local result = {}
    local anchoridx = {}
    for _, obj in pairs(t) do
        if not anchoridx[obj] then
            parent_anchor_value(t, obj, anchoridx)
        end
        table.insert(result, obj)
    end
    table.sort(result, function(a, b)
        return anchoridx[a][1] < anchoridx[b][1]
            or anchoridx[a][1] == anchoridx[b][1]
                and anchoridx[a][2] > anchoridx[b][2]
            or anchoridx[a][1] == anchoridx[b][1]
                and anchoridx[a][2] == anchoridx[b][2]
                and anchoridx[a][3] < anchoridx[b][3]
    end)
    return result
end


local function apply_style(result, style)
    for k, v in pairs(style) do
        assert(type(k) == 'number')
        for _, obj in pairs(result) do
            v.apply(obj)
        end
    end
    return result
end


local queryResultFunctions = {}


local function queryResult(table)
    local k, v = nil, nil
    local meta = {
        __call = function(self)
            k, v = next(self, k)
            if k ~= nil then
                return v
            end
        end,
        __index = function(self, attr)
            return function(self, ...)
                if self ~= table then
                    return queryResultFunctions[attr](table, self, ...)
                else
                    for i = 1, #self do
                        local name = rawget(self, i):GetName()
                        assert(rawget(self, i)[attr], rawget(self, i):GetObjectType() .. (name and (' ' .. name) or '') .. ' has no function named ' .. attr)
                    end
                    for i = 1, #self do
                        rawget(self, i)[attr](rawget(self, i), ...)
                    end
                    return self
                end
            end
        end,
    }
    return setmetatable(table, meta)
end


function queryResultFunctions:filter(fn)
    local filtered = {}
    for i=1, #self do
        local v = rawget(self, i)
        if fn(v) then
            filtered[#filtered+1] = v
        end
    end
    return queryResult(filtered)
end

function queryResultFunctions:sort(fn)
    if fn then
        return queryResult(fn(self))
    else
        return queryResult(sortByAnchors(self))
    end
end

function queryResultFunctions:all()
    return { unpack(self) }
end


local pattern_cache = {}
local function compile_pattern(str)
    if pattern_cache[str] then return pattern_cache[str] end

    if str:find(',') then
        local multipattern = {}
        for part in str:gmatch('%s*([^,]+)') do
            table.insert(multipattern, compile_pattern(part))
        end
        local fn = function(obj, fn)
            for i=1, #multipattern do
                multipattern[i](obj, fn)
            end
        end
        pattern_cache[str] = fn
        return fn
    else
        local selector, remainder = str:match('^([^>]*)>?(.*)$') -- split_at_find(str, '[>%s]')
        selector = strtrim(selector)
        remainder = strtrim(remainder)

        local iter_regions = false
        local iter_anim = false
        local iter_children = false
        local conditions = {}

        local class = nil
        local class_code = nil
        local attribute = nil
        local attribute_code = nil
        local attribute_complex = nil
        local global_name = nil
        local global_name_code = nil
        local global_name_complex = nil

        for char, identifier in selector:gmatch '([%.%:%@])%s*([^%.%:%@]+)' do
            assert(not conditions[char], 'Same element cannot have multiple `' .. char .. '` selectors')
            conditions[char] = identifier
            if char == '@' then
                assert(not identifier:find('%*') and not identifier:find('#'), 'Complex matching for classes not supported')
                iter_regions = true -- TODO: CLASSES_REGIONS[identifier]
                iter_anim = true -- TODO: CLASSES_ANIM[identifier]
                iter_children = true -- TODO: CLASSES_CHILDREN[identifier]
                class = identifier
                class_code = 'child:GetObjectType() == "' .. identifier .. '"'
            elseif char == '.' then
                if identifier == '*' then
                    iter_regions, iter_anim, iter_children = true, true, true
                    attribute = ''
                    attribute_code = 'true'
                    attribute_complex = true
                elseif identifier == '\0' then
                    iter_regions, iter_anim, iter_children = true, true, true
                    attribute_code = 'attrs[child] == nil'
                    attribute = ''
                    attribute_complex = true
                elseif not IsIdentifierName(identifier) then
                    iter_regions, iter_anim, iter_children = true, true, true
                    attribute = '^' .. identifier:gsub("%*", ".*"):gsub("#", "%%d+") .. '$'
                    attribute_code = 'attrs[child] and attrs[child]:match("' .. attribute .. '")'
                    attribute_complex = true
                else
                    attribute = identifier
                    attribute_code = 'not_used!'
                    attribute_complex = false
                end
            elseif char == ':' then
                if not IsIdentifierName(identifier) then
                    iter_regions, iter_anim, iter_children = true, true, true
                    global_name_complex = true
                    global_name = '^' .. identifier:gsub("%*", ".*"):gsub("#", "%%d+") .. '$'
                    global_name_code = 'child:GetName() and child:GetName():match("' .. global_name .. '")'
                else
                    global_name_complex = false
                    global_name_code = 'child:GetName() == ' .. identifier
                    global_name = identifier
                end
            end
        end

        assert(class or attribute or global_name, 'Invalid pattern `' .. selector .. '`')

        local remainder_compiled = nil
        if #remainder > 0 then
            remainder_compiled = compile_pattern(remainder)
        end

        local code_apply
        if remainder_compiled then
            code_apply = 'remainder_compiled(child, fn)'
        else
            code_apply = 'fn(child)'
        end

        local code = 'local obj, fn, remainder_compiled = ...\n' ..
                     'if not obj.GetRegions or not obj.GetChildren then return end\n'

        if attribute and not attribute_complex then
            assert(not class, 'Cannot combine simple attribute with class selector')
            assert(not global_name, 'Cannot combine simple attribute with global name selector')
            if tonumber(attribute) then
                code = code ..
                    'local child = obj[' .. attribute .. ']\n' ..
                    'if child and child:GetParent() == obj then\n' ..
                    '    ' .. code_apply .. '\n' ..
                    'end'
            else
                code = code ..
                    'local child = obj.' .. attribute .. '\n' ..
                    'if child and child:GetParent() == obj then\n' ..
                    '    ' .. code_apply .. '\n' ..
                    'end'
            end
        elseif global_name and not global_name_complex then
            assert(not attribute, 'Cannot combine simple global name with attribute')
            assert(not class, 'Cannot combine simple global name with class selector')
            code = code ..
                'local child = _G.' .. global_name .. '\n' ..
                'if child and child:GetParent() == obj then\n' ..
                '    ' .. code_apply .. '\n' ..
                'end'
        else
            local match_code = ''

            if attribute_code then
                match_code = attribute_code
                if attribute_code ~= 'true' then
                    code = code .. 'local attrs = {}\n' ..
                                   'for k, v in pairs(obj) do\n' ..
                                   '    attrs[v] = k\n' ..
                                   'end\n'
                end
            end

            if global_name_code then
                if #match_code > 0 then
                    match_code = match_code .. ' and ' .. global_name_code
                else
                    match_code = global_name_code
                end
            end

            if class_code then
                if #match_code > 0 then
                    match_code = match_code .. ' and ' .. class_code
                else
                    match_code = class_code
                end
            end

            code = code ..
                'local function apply(...)\n' ..
                '    for i=1, select(\'#\', ...) do\n' ..
                '        local child = select(i, ...)\n' ..
                '        if ' .. match_code .. ' then\n' ..
                '            ' .. code_apply .. '\n' ..
                '        end\n' ..
                '    end\n' ..
                'end\n'

            if iter_regions then
                code = code .. 'apply(obj:GetRegions())\n'
            end
            if iter_children then
                code = code .. 'apply(obj:GetChildren())\n'
            end
            if iter_anim then
                code = code .. 'apply(obj:GetAnimationGroups())\n'
            end
        end

        local compiled
        local intermediate = assert(loadstring(code))
        if remainder_compiled then
            compiled = function(obj, fn)
                intermediate(obj, fn, remainder_compiled)
            end
        else
            compiled = intermediate
        end
        pattern_cache[str] = compiled
        return compiled
    end
end


local function query(obj, pattern)
    if not obj.GetRegions or not obj.GetChildren then return queryResult {} end
    if type(pattern) == 'table' then
        return apply_style({ obj }, pattern)
    end

    local compiled = compile_pattern(pattern)

    local result = {}
    compiled(obj, function(child)
        table.insert(result, child)
    end)
    return queryResult(result)

end


LQT.query = query
LQT.matches = matches


if false then

    local root = CreateFrame('Frame') --[[@as any]]
    root.child1 = CreateFrame('Frame', nil, root) --[[@as any]]
    root.child1.child1 = CreateFrame('Frame', nil, root.child1) --[[@as any]]
    root.child2 = CreateFrame('Frame', nil, root) --[[@as any]]
    root.child3 = root:CreateFontString() --[[@as any]]

    for child in query(root, '.child1') do
        child.first = true
    end
    assert(root.child1.first)

    for child in query(root, '@Frame') do
        child.frame = true
    end
    assert(root.child1.frame)
    assert(root.child2.frame)
    assert(not root.child3.frame)

    for child in query(root, '.*') do
       child.all = true
    end
    assert(root.child1.all)
    assert(root.child2.all)
    assert(root.child3.all)

    for child in query(root, '.child1 > .child1') do
        child.nested = true
    end
    assert(root.child1.child1.nested)

end

