import Lean
import NixParserLean.Core

namespace NixParserLean
namespace Core
namespace Eval

mutual
inductive Value where
  | int : Int -> Value
  | float : String -> Value
  | str : String -> Value
  | bool : Bool -> Value
  | null : Value
  | path : String -> Value
  | list : List Value -> Value
  | attrset : List (String × Value) -> Value
  | closure : List (String × EnvValue) -> LambdaParam -> Expr -> Value
  deriving Repr, Inhabited

inductive EnvValue where
  | value : Value -> EnvValue
  | inherited : String -> List (String × EnvValue) -> EnvValue
  | thunk : String -> List (String × EnvValue) -> List Binding -> Expr -> EnvValue
  deriving Repr, Inhabited
end

mutual
def beqValue : Value -> Value -> Bool
  | .int left, .int right => left == right
  | .float left, .float right => left == right
  | .str left, .str right => left == right
  | .bool left, .bool right => left == right
  | .null, .null => true
  | .path left, .path right => left == right
  | .list left, .list right => beqValues left right
  | .attrset left, .attrset right => beqAttrs left right
  | _, _ => false

def beqValues : List Value -> List Value -> Bool
  | [], [] => true
  | left :: lefts, right :: rights => beqValue left right && beqValues lefts rights
  | _, _ => false

def beqAttrs : List (String × Value) -> List (String × Value) -> Bool
  | [], [] => true
  | (leftName, leftValue) :: lefts, (rightName, rightValue) :: rights =>
      leftName == rightName && beqValue leftValue rightValue && beqAttrs lefts rights
  | _, _ => false
end

instance : BEq Value where
  beq := beqValue

abbrev Env := List (String × EnvValue)
abbrev M := Except String
def defaultFuel : Nat := 200

private def unsupported (feature : String) : M α :=
  throw s!"eval error: unsupported {feature}"

private def lookupAttr (name : String) : List (String × Value) -> Option Value
  | [] => none
  | (candidate, value) :: rest =>
      if candidate == name then some value else lookupAttr name rest

private def duplicateAttrError (names : List String) : M α :=
  throw ("eval error: duplicate attribute '" ++ ".".intercalate names ++ "'")

private def addAttr (path : List String) (name : String) (value : Value) :
    List (String × Value) -> M (List (String × Value))
  | [] => pure [(name, value)]
  | (candidate, existing) :: rest =>
      if candidate == name then
        duplicateAttrError path
      else do
        let rest ← addAttr path name value rest
        pure ((candidate, existing) :: rest)

private def replaceAttr (name : String) (value : Value) : List (String × Value) ->
    List (String × Value)
  | [] => []
  | (candidate, existing) :: rest =>
      if candidate == name then
        (candidate, value) :: rest
      else
        (candidate, existing) :: replaceAttr name value rest

private def singletonPathAttr : List String -> Value -> M Value
  | [], _ => throw "eval error: empty attribute path"
  | [name], value => pure (.attrset [(name, value)])
  | name :: names, value => do
      pure (.attrset [(name, ← singletonPathAttr names value)])

private def insertPathAttrFrom (pathPrefix names : List String) (value : Value) :
    List (String × Value) -> M (List (String × Value))
  | attrs => do
      match names with
      | [] => throw "eval error: empty attribute path"
      | [name] => addAttr (pathPrefix ++ [name]) name value attrs
      | name :: rest =>
          let child ←
            match lookupAttr name attrs with
            | none => singletonPathAttr rest value
            | some (.attrset childAttrs) => do
                let childAttrs ← insertPathAttrFrom (pathPrefix ++ [name]) rest value childAttrs
                pure (.attrset childAttrs)
            | some _ =>
                throw s!"eval error: dynamic attribute path prefix '{name}' is not an attrset"
          match lookupAttr name attrs with
          | none => addAttr (pathPrefix ++ [name]) name child attrs
          | some _ => pure (replaceAttr name child attrs)

private def insertPathAttr (names : List String) (value : Value) :
    List (String × Value) -> M (List (String × Value)) :=
  insertPathAttrFrom [] names value

private def hasDynamicBinding : List Binding -> Bool
  | [] => false
  | .dynamicAssign _ _ :: _ => true
  | .inheritAssign _ :: bindings => hasDynamicBinding bindings
  | .staticAssign _ _ :: bindings => hasDynamicBinding bindings

private def attrEnv : List (String × Value) -> Env
  | [] => []
  | (name, value) :: attrs => (name, .value value) :: attrEnv attrs

private def intToFloat : Int -> Float
  | .ofNat n => n.toFloat
  | .negSucc n => -((n + 1).toFloat)

private def parseFloatValue (raw : String) : M Float :=
  match Lean.Json.parse raw with
  | .ok (.num number) => pure number.toFloat
  | _ => throw s!"eval error: invalid float literal '{raw}'"

private def numericToFloat : Value -> M Float
  | .int value => pure (intToFloat value)
  | .float raw => parseFloatValue raw
  | _ => throw "eval error: numeric operator expects an int or float"

private def setAttr (name : String) (value : Value) : List (String × Value) ->
    List (String × Value)
  | [] => [(name, value)]
  | (candidate, existing) :: rest =>
      if candidate == name then
        (candidate, value) :: rest
      else
        (candidate, existing) :: setAttr name value rest

private def updateAttrs : List (String × Value) -> List (String × Value) ->
    List (String × Value)
  | attrs, [] => attrs
  | attrs, (name, value) :: rest => updateAttrs (setAttr name value attrs) rest

partial def evalUnary : UnaryOp -> Value -> M Value
  | .not, .bool value => pure (.bool (!value))
  | .not, _ => throw "eval error: boolean negation expects a bool"
  | .negate, .int value => pure (.int (-value))
  | .negate, _ => throw "eval error: numeric negation expects an int"

mutual
def equalValue : Value -> Value -> M Bool
  | .int left, .int right => pure (left == right)
  | .float left, .float right => pure (left == right)
  | .str left, .str right => pure (left == right)
  | .bool left, .bool right => pure (left == right)
  | .null, .null => pure true
  | .path left, .path right => pure (left == right)
  | .list left, .list right => equalValues left right
  | .attrset left, .attrset right => equalAttrs left right
  | .closure _ _ _, .closure _ _ _ => throw "eval error: function values cannot be compared"
  | _, _ => throw "eval error: equality operands must have the same type"

def equalValues : List Value -> List Value -> M Bool
  | [], [] => pure true
  | [], _ :: _ => pure false
  | _ :: _, [] => pure false
  | left :: lefts, right :: rights => do
      if ← equalValue left right then equalValues lefts rights else pure false

def equalAttrs : List (String × Value) -> List (String × Value) -> M Bool
  | [], [] => pure true
  | [], _ :: _ => pure false
  | _ :: _, [] => pure false
  | (leftName, leftValue) :: lefts, (rightName, rightValue) :: rights => do
      if leftName == rightName then
        if ← equalValue leftValue rightValue then equalAttrs lefts rights else pure false
      else
        pure false
end

partial def evalBinary : BinaryOp -> Value -> Value -> M Value
  | .add, .int left, .int right => pure (.int (left + right))
  | .add, left, right => do
      pure (.float (Float.toString ((← numericToFloat left) + (← numericToFloat right))))
  | .subtract, .int left, .int right => pure (.int (left - right))
  | .subtract, left, right => do
      pure (.float (Float.toString ((← numericToFloat left) - (← numericToFloat right))))
  | .multiply, .int left, .int right => pure (.int (left * right))
  | .multiply, left, right => do
      pure (.float (Float.toString ((← numericToFloat left) * (← numericToFloat right))))
  | .divide, .int _, .int 0 => throw "eval error: division by zero"
  | .divide, .int left, .int right => pure (.int (left / right))
  | .divide, left, right => do
      let right ← numericToFloat right
      if right == 0.0 then
        throw "eval error: division by zero"
      else
        pure (.float (Float.toString ((← numericToFloat left) / right)))
  | .less, .int left, .int right => pure (.bool (left < right))
  | .less, left, right => do
      pure (.bool ((← numericToFloat left) < (← numericToFloat right)))
  | .greater, .int left, .int right => pure (.bool (left > right))
  | .greater, left, right => do
      pure (.bool ((← numericToFloat left) > (← numericToFloat right)))
  | .lessOrEqual, .int left, .int right => pure (.bool (left <= right))
  | .lessOrEqual, left, right => do
      pure (.bool ((← numericToFloat left) <= (← numericToFloat right)))
  | .greaterOrEqual, .int left, .int right => pure (.bool (left >= right))
  | .greaterOrEqual, left, right => do
      pure (.bool ((← numericToFloat left) >= (← numericToFloat right)))
  | .concat, .list left, .list right => pure (.list (left ++ right))
  | .concat, _, _ => throw "eval error: list concatenation expects lists"
  | .update, .attrset left, .attrset right => pure (.attrset (updateAttrs left right))
  | .update, _, _ => throw "eval error: attribute update expects attrsets"
  | .equal, left, right => do
      pure (.bool (← equalValue left right))
  | .notEqual, left, right => do
      pure (.bool (!(← equalValue left right)))
  | .and, .bool left, .bool right => pure (.bool (left && right))
  | .or, .bool left, .bool right => pure (.bool (left || right))
  | .implies, .bool left, .bool right => pure (.bool ((!left) || right))
  | op, _, _ => throw s!"eval error: unsupported operands for binary operator {repr op}"

def paramEntryNames : List ParamEntry -> List String
  | [] => []
  | entry :: entries => entry.name :: paramEntryNames entries

def containsName (name : String) : List String -> Bool
  | [] => false
  | candidate :: names => candidate == name || containsName name names

def findExtraAttr? (allowed : List String) : List (String × Value) -> Option String
  | [] => none
  | (name, _) :: attrs =>
      if containsName name allowed then findExtraAttr? allowed attrs else some name

mutual
partial def eval (fuel : Nat) (stack : List String) (env : Env) : Expr -> M Value
  | .int value => pure (.int value)
  | .float value => pure (.float value)
  | .str parts => do
      pure (.str (← evalStringParts fuel stack env "string" parts))
  | .bool value => pure (.bool value)
  | .null => pure .null
  | .ident name => lookupName fuel stack name env
  | .path path => pure (.path path)
  | .list items => do
      pure (.list (← evalList fuel stack env items))
  | .attrset recursive bindings => do
      if recursive && hasDynamicBinding bindings then
        unsupported "dynamic recursive attribute binding evaluation"
      else if recursive then
        pure (.attrset (← evalBindings fuel stack (recursiveEnv "attribute" env bindings) bindings))
      else
        pure (.attrset (← evalBindings fuel stack env bindings))
  | .letIn bindings body => do
      if hasDynamicBinding bindings then
        unsupported "dynamic let binding evaluation"
      else
        eval fuel stack (letEnv env bindings) body
  | .lambda param body => pure (.closure env param body)
  | .ifThenElse condition thenBranch elseBranch => do
      match ← eval fuel stack env condition with
      | .bool true => eval fuel stack env thenBranch
      | .bool false => eval fuel stack env elseBranch
      | _ => throw "eval error: if condition must be a bool"
  | .assertExpr condition body => do
      match ← eval fuel stack env condition with
      | .bool true => eval fuel stack env body
      | .bool false => throw "eval error: assertion failed"
      | _ => throw "eval error: assertion condition must be a bool"
  | .withExpr scope body => do
      match ← eval fuel stack env scope with
      | .attrset attrs => eval fuel stack (env ++ attrEnv attrs) body
      | _ => throw "eval error: with scope must be an attrset"
  | .select base path none => do
      let names ← evalAttrPath fuel stack env path
      selectPath (← eval fuel stack env base) names
  | .select base path (some defaultExpr) => do
      let names ← evalAttrPath fuel stack env path
      match selectPath? (← eval fuel stack env base) names with
      | some value => pure value
      | none => eval fuel stack env defaultExpr
  | .hasAttr base path => do
      let names ← evalAttrPath fuel stack env path
      pure (.bool ((selectPath? (← eval fuel stack env base) names).isSome))
  | .app (.ident "import") _ => unsupported "import evaluation"
  | .app function argument => do
      match ← eval fuel stack env function with
      | .closure closureEnv param body => do
          let argument ← eval fuel stack env argument
          let env ← bindParam fuel stack param argument closureEnv
          eval fuel stack env body
      | _ => throw "eval error: function application expects a function"
  | .unary op inner => do
      evalUnary op (← eval fuel stack env inner)
  | .binary op left right => do
      evalBinary op (← eval fuel stack env left) (← eval fuel stack env right)

partial def lookupName (fuel : Nat) (stack : List String) (name : String) : Env -> M Value
  | [] => throw s!"eval error: unbound identifier '{name}'"
  | (candidate, entry) :: rest =>
      if candidate == name then
        match entry with
        | .value value => pure value
        | .inherited inheritedName baseEnv => lookupName fuel stack inheritedName baseEnv
        | .thunk context baseEnv bindings expr =>
            if containsName name stack then
              throw s!"eval error: recursive {context} binding '{name}'"
            else
              match fuel with
              | 0 => throw "eval error: evaluation fuel exhausted"
              | fuel + 1 =>
                  eval fuel (name :: stack) (recursiveEnv context baseEnv bindings) expr
      else
        lookupName fuel stack name rest

partial def bindParam (fuel : Nat) (stack : List String) (param : LambdaParam) (argument : Value)
    (env : Env) : M Env :=
  match param with
  | .ident name => pure ((name, .value argument) :: env)
  | .attrset paramSet => bindParamSet fuel stack paramSet argument env
  | .alias name (.attrset paramSet) =>
      bindParamSet fuel stack paramSet argument ((name, .value argument) :: env)
  | .alias _ _ => unsupported "aliased non-attrset lambda parameter evaluation"

partial def bindParamSet (fuel : Nat) (stack : List String) (paramSet : ParamSet)
    (argument : Value) (env : Env) : M Env :=
  match argument with
  | .attrset attrs => do
      if !paramSet.ellipsis then
        match findExtraAttr? (paramEntryNames paramSet.entries) attrs with
        | some name => throw s!"eval error: unexpected function argument attribute '{name}'"
        | none => pure ()
      bindParamEntries fuel stack attrs paramSet.entries env
  | _ => throw "eval error: attribute-set lambda parameter expects an attrset"

partial def bindParamEntries (fuel : Nat) (stack : List String) (attrs : List (String × Value)) :
    List ParamEntry -> Env -> M Env
  | [], env => pure env
  | entry :: entries, env => do
      let value ←
        match lookupAttr entry.name attrs with
        | some value => pure value
        | none =>
            match entry.default? with
            | some defaultExpr => eval fuel stack env defaultExpr
            | none => throw s!"eval error: missing function argument attribute '{entry.name}'"
      bindParamEntries fuel stack attrs entries ((entry.name, .value value) :: env)

partial def evalList (fuel : Nat) (stack : List String) (env : Env) : List Expr -> M (List Value)
  | [] => pure []
  | item :: items => do
      let item ← eval fuel stack env item
      let items ← evalList fuel stack env items
      pure (item :: items)

partial def evalBindings (fuel : Nat) (stack : List String) (env : Env) :
    List Binding -> M (List (String × Value))
  | [] => pure []
  | binding :: bindings => do
      let attrs ← evalBindings fuel stack env bindings
      evalBindingInto fuel stack env binding attrs

partial def evalBindingInto (fuel : Nat) (stack : List String) (env : Env) (binding : Binding)
    (attrs : List (String × Value)) : M (List (String × Value)) := do
  match binding with
  | .staticAssign name expr => do
      let value ← eval fuel stack env expr
      addAttr [name] name value attrs
  | .inheritAssign name => do
      let value ← lookupName fuel stack name env
      addAttr [name] name value attrs
  | .dynamicAssign path expr => do
      let names ← evalAttrPath fuel stack env path
      let value ← eval fuel stack env expr
      insertPathAttr names value attrs

partial def letEnv (baseEnv : Env) (bindings : List Binding) : Env :=
  recursiveEnv "let" baseEnv bindings

partial def recursiveEnv (context : String) (baseEnv : Env) (bindings : List Binding) : Env :=
  thunkEntries context baseEnv bindings ++ baseEnv

partial def thunkEntries (context : String) (baseEnv : Env) (bindings : List Binding) : Env :=
  thunkEntriesGo context baseEnv bindings bindings

partial def thunkEntriesGo (context : String) (baseEnv : Env) (allBindings : List Binding) :
    List Binding -> Env
  | [] => []
  | .staticAssign name expr :: bindings =>
      (name, .thunk context baseEnv allBindings expr) ::
        thunkEntriesGo context baseEnv allBindings bindings
  | .inheritAssign name :: bindings =>
      (name, .inherited name baseEnv) ::
        thunkEntriesGo context baseEnv allBindings bindings
  | .dynamicAssign _ _ :: bindings => thunkEntriesGo context baseEnv allBindings bindings

partial def evalAttrPath (fuel : Nat) (stack : List String) (env : Env)
    (path : List AttrPathPart) : M (List String) :=
  match path with
  | [] => throw "eval error: empty attribute path"
  | part :: parts => do
      let name ← evalAttrPathPart fuel stack env part
      let names ← evalAttrPathRest fuel stack env parts
      pure (name :: names)

partial def evalAttrPathRest (fuel : Nat) (stack : List String) (env : Env) :
    List AttrPathPart -> M (List String)
  | [] => pure []
  | part :: parts => do
      let name ← evalAttrPathPart fuel stack env part
      let names ← evalAttrPathRest fuel stack env parts
      pure (name :: names)

partial def evalAttrPathPart (fuel : Nat) (stack : List String) (env : Env) :
    AttrPathPart -> M String
  | .static name => pure name
  | .dynamicString parts => evalStringParts fuel stack env "dynamic attribute" parts

partial def evalStringParts (fuel : Nat) (stack : List String) (env : Env) (context : String) :
    List StringPart -> M String
  | [] => pure ""
  | .text text :: parts => do
      let rest ← evalStringParts fuel stack env context parts
      pure (text ++ rest)
  | .interpolation expr :: parts => do
      let text ← coerceStringPart context (← eval fuel stack env expr)
      let rest ← evalStringParts fuel stack env context parts
      pure (text ++ rest)

partial def coerceStringPart (context : String) : Value -> M String
  | .str text => pure text
  | value =>
      if context == "dynamic attribute" then
        throw "eval error: dynamic attribute interpolation expects a string"
      else
        match value with
        | .int value => pure (toString value)
        | .bool true => pure "true"
        | .bool false => pure "false"
        | .null => pure "null"
        | _ => throw s!"eval error: {context} interpolation expects a string-compatible value"

partial def selectPath? : Value -> List String -> Option Value
  | value, [] => some value
  | .attrset attrs, name :: names => do
      let value ← lookupAttr name attrs
      selectPath? value names
  | _, _ :: _ => none

partial def selectPath (value : Value) (names : List String) : M Value :=
  match selectPath? value names with
  | some value => pure value
  | none => throw ("eval error: missing attribute '" ++ ".".intercalate names ++ "'")
end

def evaluateWithFuel (fuel : Nat) (expr : Expr) : M Value :=
  eval fuel [] [] expr

def evaluate (expr : Expr) : M Value :=
  evaluateWithFuel defaultFuel expr

end Eval

def evalWithFuel (fuel : Nat) (expr : Expr) : Except String Eval.Value :=
  Eval.evaluateWithFuel fuel expr

def eval (expr : Expr) : Except String Eval.Value :=
  Eval.evaluate expr

end Core
end NixParserLean
