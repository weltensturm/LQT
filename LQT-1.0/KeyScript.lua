---@class Addon
local Addon = select(2, ...)

---@class LQT
local LQT = Addon.LQT


local get_context = LQT.internal.get_context
local FrameExtensions = LQT.FrameExtensions
local IsFrameProxy = LQT.IsFrameProxy
local FrameProxyTargetKey = LQT.FrameProxyTargetKey


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


local ScriptMt = {
    lqtKeyCompile = function(key, cb)
        local context = key[2]
        key = key[1]
        return function(self, parent)

            self.lqtHooks = self.lqtHooks or {}
            self.lqtHookLibrary = self.lqtHookLibrary or {}

            if IsFrameProxy(cb) then
                local target, targetKey = FrameProxyTargetKey(self, cb)
                self.lqtHookLibrary[context or get_context()] = {
                    [key] = function(_, ...)
                        target[targetKey](target, ...)
                    end
                }
            else
                self.lqtHookLibrary[context or get_context()] = {
                    [key] = cb
                }
            end
            if not self.lqtHooks[key] then
                local hooks = self.lqtHooks
                self:HookScript(key, function(self, ...)
                    hooks[key](self, ...)
                end)
            end

            local build = {}
            for context, t in pairs(self.lqtHookLibrary) do
                if t[key] then
                    table.insert(build, t[key])
                end
            end
            self.lqtHooks[key] = ChainFunctions(build)

        end
    end
}

---@class LQT.Script
---@field [LQT.GenericScript] WidgetMethodKey
LQT.Script = setmetatable({}, {
    __index = function(self, key)
        return setmetatable({ key, get_context() }, ScriptMt)
    end
})
