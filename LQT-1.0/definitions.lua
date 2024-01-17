---@meta

---@class LQT
local LQT = {}


---@class LQT.AnyWidget: UIParent, EditBox, Texture, AnimationGroup
---@field GetParent fun(self: LQT.AnyWidget, ...): any

---@class LQT.ClassKey

---@alias LQT.WidgetMethod fun(self: LQT.AnyWidget|any, ...): ...

---@class LQT.ClassBody
---@field [LQT.ClassKey] LQT.WidgetMethod|false
---@field [integer] fun(self: LQT.AnyWidget, parent: LQT.AnyWidget) | LQT.StyleChain
---@field [string] LQT.WidgetMethod | LQT.StyleChain | any


-- -@alias LQT.WidgetMethod fun(self: LQT.AnyWidget, ...): LQT.StyleChain

-- -@class LQT.WidgetMethod
-- -@overload fun(self: LQT.AnyWidget|any, ...)


---@class LQT.StyleChain: LQT.StyleFunctionProxy
---@class LQT.StyleChain: LQT.internal.StyleAttributes
---@field [string] fun(self: LQT.AnyWidget|any, ...): LQT.StyleChain
---@overload fun(a: LQT.ClassBody): LQT.StyleChain
---@operator concat(LQT.StyleChain): LQT.StyleChain
----@class LQT.StyleChain: LQT.AnyWidget


---@class LQT.StyleFunctionProxy
local StyleFunctionProxy = {}

---@generic Tr
---@param constructor fun(parent: LQT.AnyWidget, globalName?: string, ...): Tr
--@return LQT.BoundStyleChain<Tr> -- this kills the cat
---@return LQT.StyleChain
function StyleFunctionProxy.constructor(constructor) end


---@generic T
---@param parent? LQT.AnyWidget | ScriptRegion
---@param globalName string?
---@return Region
function StyleFunctionProxy.new(parent, globalName, ...) end



---@class LQT.BoundFunctionProxy
local BoundStyleFunctions = {}

---@param parent? LQT.AnyWidget
---@return LQT.AnyWidget
function BoundStyleFunctions.new(parent, ...) end


---@class LQT.internal
local internal = {}


---@generic T
---@param parent LQT.StyleChain | nil
---@param new table<LQT.internal.FIELDS, any>
---@return LQT.StyleChain
function internal.chain_extend(parent, new) end


---@return LQT.AnyWidget
function LQT.FrameProxy() end


--[[
---@class LQT.BoundWidgetDescription<T>
----@field [LQT.Event] function
---@field [integer] fun(self: T, parent: LQT.AnyWidget) | LQT.BoundStyleChain<T>
---@field [string] fun(self: T, ...) | LQT.BoundStyleChain<T>



---@class LQT.BoundWidgetMethodProxy<T>
---@field [string] LQT.BoundWidgetMethod<T>

---@alias LQT.BoundStyleChainCall<T> fun(self: LQT.BoundStyleChain<T>, ...): LQT.BoundStyleChain<T>

---@alias LQT.BoundWidgetMethod<T> fun(self: LQT.BoundStyleChain<T>, ...): LQT.BoundStyleChain<T>

---@class LQT.BoundStyleChainBase<T>: LQT.BoundFunctionProxy
---@class LQT.BoundStyleChainBase<T>: LQT.internal.StyleAttributes
--@class LQT.BoundStyleChainBase: LQT.BoundStyleChainCall
---@class LQT.BoundStyleChainBase<T>: LQT.BoundWidgetMethodProxy<T>
---@operator concat(LQT.BoundStyleChain<T>): LQT.BoundStyleChain<T>
---@operator concat(LQT.StyleChain): LQT.BoundStyleChain<T>
---@overload fun(obj: LQT.BoundWidgetDescription<T>): LQT.BoundStyleChain<T>
----@class LQT.BoundStyleChain<T>: T
----@class LQT.BoundStyleChain<T>
----@overload fun(obj: LQT.ClassBody): LQT.BoundStyleChain<T>

---@alias LQT.BoundStyleChain<T> LQT.BoundStyleChainBase | LQT.BoundStyleChainCall<T>

---@generic T
---@param constructor fun(parent: LQT.AnyWidget, globalName?: string, ...): T
---@return LQT.BoundStyleChain<T>
function BoundStyleFunctions.constructor(constructor) end

--@generic T
--@param parent LQT.BoundStyleChain<T> | nil
--@param new table<LQT.internal.FIELDS, any>
--@return LQT.BoundStyleChain<T>
--function internal.chain_extend(parent, new) end

]]
