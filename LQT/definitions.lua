---@meta

---@class LQT
local LQT = {}


---@class LQT.AnyWidget: UIParent, EditBox, Texture, AnimationGroup
---@field GetParent fun(self: LQT.AnyWidget, ...): any

---@class LQT.WidgetDescription
---@field [WidgetMethodKey] LQT.WidgetMethod
---@field [integer] fun(self: LQT.AnyWidget, parent: LQT.AnyWidget) | LQT.StyleChain
---@field [string] (fun(self: LQT.AnyWidget|any, ...): ...) | LQT.StyleChain | any

---@class LQT.WidgetMethod
---@overload fun(self: LQT.AnyWidget, ...): LQT.StyleChain

---@class LQT.WidgetFunctionProxy
---@field [string] LQT.WidgetMethod
----@field [string] fun(self: LQT.AnyWidget, ...): LQT.StyleChain

---@class LQT.StyleChainCall
---@overload fun(a: LQT.WidgetDescription): LQT.StyleChain

---@alias LQT.StyleConstructor function

---@class LQT.StyleChain: LQT.StyleFunctionProxy
---@class LQT.StyleChain: LQT.internal.StyleAttributes
---@class LQT.StyleChain: LQT.WidgetFunctionProxy
---@class LQT.StyleChain: LQT.StyleChainCall
----@class LQT.StyleChain: LQT.AnyWidget
---@operator concat(LQT.StyleChain): LQT.StyleChain
---@overload fun(obj: LQT.WidgetDescription): LQT.StyleChain




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
----@overload fun(obj: LQT.WidgetDescription): LQT.BoundStyleChain<T>

---@alias LQT.BoundStyleChain<T> LQT.BoundStyleChainBase | LQT.BoundStyleChainCall<T>


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
---@return T
function StyleFunctionProxy.new(parent, globalName, ...) end



---@class LQT.BoundFunctionProxy
local BoundStyleFunctions = {}

---@param parent? LQT.AnyWidget
---@return LQT.AnyWidget
function BoundStyleFunctions.new(parent, ...) end

---@generic T
---@param constructor fun(parent: LQT.AnyWidget, globalName?: string, ...): T
---@return LQT.BoundStyleChain<T>
function BoundStyleFunctions.constructor(constructor) end


---@class LQT.internal
local internal = {}


---@generic T
---@param parent LQT.StyleChain | nil
---@param new table<LQT.internal.FIELDS, any>
---@return LQT.StyleChain
function internal.chain_extend(parent, new) end


--@generic T
--@param parent LQT.BoundStyleChain<T> | nil
--@param new table<LQT.internal.FIELDS, any>
--@return LQT.BoundStyleChain<T>
--function internal.chain_extend(parent, new) end


---@return LQT.AnyWidget
function LQT.FrameProxy() end

