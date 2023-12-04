---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT

---@class LQT.FrameExtensions: LQT.AnyWidget
LQT.FrameExtensions = {}

---@class LQT.FrameExtensions
local FrameExtensions = LQT.FrameExtensions

local query = LQT.query


local FrameProxyMt = LQT.FrameProxyMt
local ApplyFrameProxy = LQT.ApplyFrameProxy
local FrameProxyTargetKey = LQT.FrameProxyTargetKey


local CORNER_TO_VEC = {
    TOPLEFT = { 1, -1 },
    TOPRIGHT = { -1, -1 },
    BOTTOMLEFT = { 1, 1 },
    BOTTOMRIGHT = { -1, 1 },
    TOP = { 0, 1 },
    BOTTOM = { 0, -1 },
    LEFT = { -1, 0 },
    RIGHT = { 1, 0 },
    CENTER = { 0, 0 }
}


local function values(table)
    local k, v = nil, nil
    return function()
        k, v = next(table, k)
        if k ~= nil then
            return v
        end
    end
end


function FrameExtensions:FitToChildren()
    local height = 0
    local parent_top = self:GetTop()
    if parent_top then
        for child in query(self, '.*') do
            if child:IsShown() and (child:GetObjectType() ~= "Frame" or child:GetChildren() or child:GetRegions()) then
                local bottom = child:GetBottom()
                if bottom and parent_top-bottom > height then
                    height = parent_top-bottom
                end
            end
        end
        self:SetHeight(height + self:GetEffectiveScale())
    end
end


function FrameExtensions:FitToChildren2()
    -- top-to-bottom only
    local max_bottom = 0
    local anchors = {}
    -- print('FitToChildren', self:GetName())
    for child in self'.*' do
        if child:GetObjectType() ~= "Frame" or child:GetChildren() or child:GetRegions() then
            local from, target, to, local_x, local_y = child:GetPoint()
            if to then
                local top, height, bottom = 0, child:GetHeight(), 0
                if target == self then
                    top = local_y
                    bottom = local_y - height
                else
                    local target_rect = anchors[target] or { y=0, h=0 }
                    top = (target_rect.y - target_rect.h*CORNER_TO_VEC[to][2]) + local_y
                    bottom = top - height
                end
                anchors[child] = { y = top, h = height }
                -- print(' -', child:GetObjectType(), child:GetName(), height, top, bottom)
                if child:IsVisible() and bottom < max_bottom then
                    max_bottom = bottom
                end
            end
        end
    end
    print(max_bottom)
    self:SetHeight(-max_bottom)
end


function FrameExtensions:CornerOffset(x, y)
    local from, parent, to, _, _ = self:GetPoint()
    if not to then return end
    local offset = CORNER_TO_VEC[to]
    self:SetPoint(to, parent, to, offset[1]*x, offset[2]*y)
end


function FrameExtensions:Scripts(scripts)
    for k, fn in pairs(scripts) do
        self:SetScript(k, fn)
    end
end


local ChainFunctions = function(t)
    local fn = nil
    for _, f in pairs(t) do
        local fn_old = fn
        if fn_old then
            fn = function(...)
                fn_old(...)
                f(...)
            end
        else
            fn = f
        end
    end
    return fn
end


local get_context = function()
    return strsplittable('\n', debugstack(3,1,1))[1]
end


local function TableHandleFrameProxies(frame, table)
    local newtable = {}
    for k, v in pairs(table) do
        if getmetatable(v) == FrameProxyMt then
            local target, key = FrameProxyTargetKey(frame, v)
            newtable[k] = function(self, ...)
                target[key](target, ...)
            end
        else
            newtable[k] = v
        end
    end
    return newtable
end


function FrameExtensions:Hooks(hooks, context)
    self.lqtHooks = self.lqtHooks or {}
    self.lqtHookLibrary = self.lqtHookLibrary or {}
    self.lqtHookLibrary[context or get_context()] = TableHandleFrameProxies(self, hooks)
    for k, f in pairs(hooks) do
        assert(f, k .. ' handler is nil, did you hook too early?')
        if not self.lqtHooks[k] then
            local hooks = self.lqtHooks
            self:HookScript(k, function(self, ...)
                hooks[k](self, ...)
            end)
        end

        local build = {}
        for context, t in pairs(self.lqtHookLibrary) do
            if t[k] then
                table.insert(build, t[k])
            end
        end
        self.lqtHooks[k] = ChainFunctions(build)
    end
end


function FrameExtensions:UnhookAll()
    for k, f in pairs(self.lqtHooks) do
        self.lqtHooks[k] = function() end
    end
    self.lqtHookLibrary = {}
end


--[[
function FrameExtensions:Events(handlers, context)
    self.lqtEvents = self.lqtEvents or {}
    self.lqtEventsLibrary = self.lqtEventsLibrary or {}
    self.lqtEventsLibrary[context or get_context()] = TableHandleFrameProxies(self, handlers)
    for event, fn in pairs(handlers) do
        assert(fn, event .. ' handler is nil, did you hook too early?')
        if not self.lqtEvents[event] then
            self:RegisterEvent(event)
            self:SetScript('OnEvent', function(self, event, ...)
                if self.lqtEvents[event] then
                    self.lqtEvents[event](self, ...)
                end
            end)
        end

        local build = {}
        for context, handlers in pairs(self.lqtEventsLibrary) do
            if handlers[event] then
                table.insert(build, handlers[event])
            end
        end
        self.lqtEvents[event] = ChainFunctions(build)
    end
end
]]


function FrameExtensions:EventHooks(handlers, context)
    if not self.lqtEventHooks then
        self.lqtEventHooks = self.lqtEventHooks or {}
        self:HookScript('OnEvent', function(self, event, ...)
            local handler = self.lqtEventHooks[event]
            if handler then
                handler(self, ...)
            end
        end)
    end
    self.lqtEventHooksLibrary = self.lqtEventHooksLibrary or {}
    self.lqtEventHooksLibrary[context or get_context()] = TableHandleFrameProxies(self, handlers)
    for event, fn in pairs(handlers) do
        assert(fn, event .. ' handler is nil, did you hook too early?')
        if not self.lqtEventHooks[event] then
            self:RegisterEvent(event)
        end

        local build = {}
        for context, handlers in pairs(self.lqtEventHooksLibrary) do
            if handlers[event] then
                table.insert(build, handlers[event])
            end
        end
        self.lqtEventHooks[event] = ChainFunctions(build)
    end
end


FrameExtensions.Events = FrameExtensions.EventHooks


function FrameExtensions:UnitEvents(handlers, context)
    if not self.lqtUnitEvents then
        self.lqtUnitEvents = self.lqtUnitEvents or {}
        self:HookScript('OnEvent', function(self, event, ...)
            local handler = self.lqtUnitEvents[event]
            if handler then
                handler(self, ...)
            end
        end)
        self.SetEventUnit = self.SetEventUnit or FrameExtensions.SetEventUnit
    end
    self.lqtUnitEventsLibrary = self.lqtUnitEventsLibrary or {}
    self.lqtUnitEventsLibrary[context or get_context()] = TableHandleFrameProxies(self, handlers)
    for event, fn in pairs(handlers) do
        assert(fn, event .. ' handler is nil, did you hook too early?')
        assert(not self.lqtEvents or not self.lqtEvents[event], 'Event ' .. event .. ' is already registered as non-unit event')
        assert(not self.lqtEventHooks or not self.lqtEventHooks[event], 'Event ' .. event .. ' is already registered as non-unit event hook')

        local build = {}
        for context, handlers in pairs(self.lqtUnitEventsLibrary) do
            if handlers[event] then
                table.insert(build, handlers[event])
            end
        end
        self.lqtUnitEvents[event] = ChainFunctions(build)
        -- self:UnregisterEvent(event)
        -- self:RegisterUnitEvent(event, unit)
    end
end


function FrameExtensions:SetEventUnit(unit, fireAll)
    if not unit then
        error('Unit is nil')
    end
    for event, fn in pairs(self.lqtUnitEvents or {}) do
        self:UnregisterEvent(event)
        self:RegisterUnitEvent(event, unit)
        if fireAll then
            fn(self)
        end
    end
end


function FrameExtensions:SetData(data)
    for k, v in pairs(TableHandleFrameProxies(self, data)) do
        self[k] = v
    end
end


local function prepareSecureHooks(self, name_or_frame, name)
    self.lqtSecurehooks = self.lqtSecurehooks or {}
    local frame = name and name_or_frame
    name = frame and assert(name) or name_or_frame
    if frame then
        local frame_name = frame:GetName()
        assert(frame_name, 'Can only securehook on named frames')
        local context = frame_name .. '.' .. name
        if not self.lqtSecurehooks[context] then
            self.lqtSecurehooks[context] = {}
            hooksecurefunc(frame, name, function(...)
                for _, securehook in pairs(self.lqtSecurehooks[context]) do
                    securehook(...)
                end
            end)
        end
        return self.lqtSecurehooks[context]
    else
        if not self.lqtSecurehooks[name] then
            self.lqtSecurehooks[name] = {}
            hooksecurefunc(name, function(...)
                for _, fn in pairs(self.lqtSecurehooks[name]) do
                    fn(...)
                end
            end)
        end
        return self.lqtSecurehooks[name]
    end
end

function FrameExtensions:RegisterReapply(style, arg1, arg2, arg3, context)
    --[[
        arg1: Frame
        arg2: Method name
        arg3 (optional): Filter
        OR
        arg1: Global function name
        arg2 (optional): Filter
        OR
        arg1: Event name
        arg2 (optional): Filter
    ]]
    local frame = type(arg1) == 'table' and arg1
    local name = frame and arg2 or arg1
    local filter = frame and arg3 or arg2

    local callback
    if filter then
        callback = function(...)
            if filter(...) then
                style.apply(self)
            end
        end
    else
        callback = function(...)
            style.apply(self)
        end
    end

    if frame then
        local hooks = prepareSecureHooks(self, frame, name)
        hooks[context or get_context()] = callback
    else
        if _G[name] then -- Global function
            local hooks = prepareSecureHooks(self, name)
            hooks[context or get_context()] = callback
        elseif name == string.upper(name) then -- Event
            FrameExtensions.EventHooks(self, { [name] = callback }, context)
        else
            assert(false, 'Could not find ' .. name)
        end
    end
end


function FrameExtensions:Strip(...)
    if ... then
        local name = self:GetName() or ''
        for v in values({...}) do
            local obj = self[v] or _G[name .. v]
            if obj and obj.GetChildren then
                FrameExtensions.Strip(obj)
            elseif obj and obj:GetObjectType() == 'Texture' then
                obj:SetTexture('')
                obj:SetAtlas('')
            end
        end
    else
        for frame in query(self, '.Frame') do
            FrameExtensions.Strip(frame)
        end
        query(self, '.Texture'):SetTexture(''):SetAtlas('')
    end
end

