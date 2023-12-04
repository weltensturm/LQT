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


local lqt_result_functions = {}


local function lqt_result(table)
    local k, v = nil, nil
    local and_then = nil
    local meta = {
        __call = function(self, style)
            if style then
                return apply_style(self, style)
            end
            k, v = next(self, k)
            if k ~= nil then
                return v
            else
                if and_then then
                    for _, fn in pairs(and_then) do
                        self[fn[1]](self, unpack(fn[2]))
                    end
                end
            end
        end,
        __index = function(self, attr)
            return function(self, ...)
                if self ~= table then
                    return lqt_result_functions[attr](table, self, ...)
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
        -- __concat = function(self, right)
        --     and_then = right
        --     for at_k, at_v in pairs(self) do
        --         for _, v in pairs(and_then) do
        --             local name = at_v:GetName()
        --             assert(at_v[v[1]], at_v:GetObjectType() .. (name and (' ' .. name) or '') .. ' has no function named ' .. v[1])
        --         end
        --     end
        --     return self
        -- end
    }
    setmetatable(table, meta)
    return table
end


function lqt_result_functions:filter(fn)
    local filtered = {}
    for _, v in pairs(self) do
        if fn(v) then
            table.insert(filtered, v)
        end
    end
    return lqt_result(filtered)
end

function lqt_result_functions:sort(fn)
    if fn then
        return lqt_result(fn(self))
    else
        return lqt_result(sortByAnchors(self))
    end
end

function lqt_result_functions:all()
    return { unpack(self) }
end


local pattern_cache = {}
local compile_pattern = function(str)
    if pattern_cache[str] then return pattern_cache[str]() end
    local multipattern
    local index_selector, index_remainder
    local global_selector, global_remainder
    if str:find(',') then
        multipattern = {}
        for part in str:gmatch('%s*([^,]+)') do
            table.insert(multipattern, part)
        end
    elseif str:sub(1, 1) == '.' then
        str = str:sub(2)
        index_selector, index_remainder = split_at_find(str, '[%.%s]')
        index_remainder = strtrim(index_remainder)
        if tonumber(index_selector) ~= nil then
            index_selector = tonumber(index_selector)
        end
    else
        global_selector, global_remainder = split_at_find(str, '[%.%s]')
        global_remainder = strtrim(global_remainder)
    end
    local compiled = function()
        return
            multipattern,
            index_selector,
            index_remainder,
            global_selector,
            global_remainder
    end
    pattern_cache[str] = compiled
    return compiled()
end


local function query(obj, pattern, found)
    if not obj.GetRegions or not obj.GetChildren then return lqt_result {} end
    if type(pattern) == 'table' then
        return apply_style({ obj }, pattern)
    end
    local root = not found
    found = found or {}
    local
        multipattern,
        index_selector,
        index_remainder,
        global_selector,
        global_remainder
            = compile_pattern(pattern)
    if multipattern then
        for i = 1, #multipattern do
            query(obj, multipattern[i], found)
        end
    elseif obj ~= UIParent and index_selector then
        if #index_remainder == 0 then
            if constructor then
                if not obj[index_selector] or obj[index_selector]:GetParent() ~= obj then
                    obj[index_selector] = constructor(obj)
                end
                return lqt_result { obj[index_selector] }
            end
        end

        ForTuple(
            function(child)
                if not found[child] and matches(child, index_selector, obj) then
                    if #index_remainder == 0 then
                        found[child] = true
                    else
                        query(child, index_remainder, found)
                    end
                end
            end,
            obj:GetRegions()
        )
        ForTuple(
            function(child)
                if not found[child] and matches(child, index_selector, obj) then
                    if #index_remainder == 0 then
                        found[child] = true
                    else
                        query(child, index_remainder, found)
                    end
                end
            end,
            obj:GetChildren()
        )
        ForTuple(
            function(child)
                if not found[child] and matches(child, index_selector, obj) then
                    if #index_remainder == 0 then
                        found[child] = true
                    else
                        query(child, index_remainder, found)
                    end
                end
            end,
            obj:GetAnimationGroups()
        )
    else
        assert(obj == UIParent)
        if #global_remainder > 0 then
            query(_G[global_selector], global_remainder, found)
        elseif _G[global_selector] then
            found[_G[global_selector]] = true
        end
    end
    if root then
        local result = {}
        for frame, _ in pairs(found) do
            table.insert(result, frame)
        end
        return lqt_result(result)
    end
end


LQT.query = query
LQT.matches = matches

