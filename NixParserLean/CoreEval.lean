import NixParserLean.Core

namespace NixParserLean
namespace Core
namespace Eval

mutual
inductive Value where
  | int : Int -> Value
  | str : String -> Value
  | bool : Bool -> Value
  | null : Value
  | list : List Value -> Value
  | attrset : List (String × Value) -> Value
  | closure : List (String × EnvValue) -> LambdaParam -> Expr -> Value
  deriving Repr, Inhabited

inductive EnvValue where
  | value : Value -> EnvValue
  | thunk : List (String × EnvValue) -> List Binding -> Expr -> EnvValue
  deriving Repr, Inhabited
end

mutual
partial def beqValue : Value -> Value -> Bool
  | .int left, .int right => left == right
  | .str left, .str right => left == right
  | .bool left, .bool right => left == right
  | .null, .null => true
  | .list left, .list right => beqValues left right
  | .attrset left, .attrset right => beqAttrs left right
  | _, _ => false

partial def beqValues : List Value -> List Value -> Bool
  | [], [] => true
  | left :: lefts, right :: rights => beqValue left right && beqValues lefts rights
  | _, _ => false

partial def beqAttrs : List (String × Value) -> List (String × Value) -> Bool
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

private def insertAttr (name : String) (value : Value) : List (String × Value) ->
    List (String × Value)
  | [] => [(name, value)]
  | (candidate, existing) :: rest =>
      if candidate == name then
        (candidate, value) :: rest
      else
        (candidate, existing) :: insertAttr name value rest

private def staticPath? : List AttrPathPart -> Option (List String)
  | [] => some []
  | .static name :: parts => do
      let names ← staticPath? parts
      some (name :: names)
  | .dynamicString _ :: _ => none

private def textOnlyString : List StringPart -> Option String
  | [] => some ""
  | .text text :: parts => do
      let rest ← textOnlyString parts
      some (text ++ rest)
  | .interpolation _ :: _ => none

private def hasDynamicBinding : List Binding -> Bool
  | [] => false
  | .dynamicAssign _ _ :: _ => true
  | .staticAssign _ _ :: bindings => hasDynamicBinding bindings

partial def evalUnary : UnaryOp -> Value -> M Value
  | .not, .bool value => pure (.bool (!value))
  | .not, _ => throw "eval error: boolean negation expects a bool"
  | .negate, .int value => pure (.int (-value))
  | .negate, _ => throw "eval error: numeric negation expects an int"

partial def evalBinary : BinaryOp -> Value -> Value -> M Value
  | .add, .int left, .int right => pure (.int (left + right))
  | .subtract, .int left, .int right => pure (.int (left - right))
  | .multiply, .int left, .int right => pure (.int (left * right))
  | .divide, .int _, .int 0 => throw "eval error: division by zero"
  | .divide, .int left, .int right => pure (.int (left / right))
  | .equal, left, right => pure (.bool (left == right))
  | .notEqual, left, right => pure (.bool (!(left == right)))
  | .and, .bool left, .bool right => pure (.bool (left && right))
  | .or, .bool left, .bool right => pure (.bool (left || right))
  | .implies, .bool left, .bool right => pure (.bool ((!left) || right))
  | op, _, _ => throw s!"eval error: unsupported operands for binary operator {repr op}"

mutual
partial def eval (fuel : Nat) (stack : List String) (env : Env) : Expr -> M Value
  | .int value => pure (.int value)
  | .str parts =>
      match textOnlyString parts with
      | some text => pure (.str text)
      | none => unsupported "string interpolation evaluation"
  | .bool value => pure (.bool value)
  | .null => pure .null
  | .ident name => lookupName fuel stack name env
  | .path _ => unsupported "path values"
  | .list items => do
      pure (.list (← evalList fuel stack env items))
  | .attrset recursive bindings => do
      if recursive then
        unsupported "recursive attribute sets"
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
  | .withExpr _ _ => unsupported "with evaluation"
  | .select base path none => do
      let names ← evalStaticPath path
      selectPath (← eval fuel stack env base) names
  | .select base path (some defaultExpr) => do
      let names ← evalStaticPath path
      match selectPath? (← eval fuel stack env base) names with
      | some value => pure value
      | none => eval fuel stack env defaultExpr
  | .hasAttr base path => do
      let names ← evalStaticPath path
      pure (.bool ((selectPath? (← eval fuel stack env base) names).isSome))
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
        | .thunk baseEnv bindings expr =>
            if containsName name stack then
              throw s!"eval error: recursive let binding '{name}'"
            else
              match fuel with
              | 0 => throw "eval error: evaluation fuel exhausted"
              | fuel + 1 => eval fuel (name :: stack) (letEnv baseEnv bindings) expr
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

partial def paramEntryNames : List ParamEntry -> List String
  | [] => []
  | entry :: entries => entry.name :: paramEntryNames entries

partial def containsName (name : String) : List String -> Bool
  | [] => false
  | candidate :: names => candidate == name || containsName name names

partial def findExtraAttr? (allowed : List String) : List (String × Value) -> Option String
  | [] => none
  | (name, _) :: attrs =>
      if containsName name allowed then findExtraAttr? allowed attrs else some name

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
      pure (insertAttr name value attrs)
  | .dynamicAssign _ _ => unsupported "dynamic attribute binding evaluation"

partial def letEnv (baseEnv : Env) (bindings : List Binding) : Env :=
  letThunkEntries baseEnv bindings ++ baseEnv

partial def letThunkEntries (baseEnv : Env) (bindings : List Binding) : Env :=
  letThunkEntriesGo baseEnv bindings bindings

partial def letThunkEntriesGo (baseEnv : Env) (allBindings : List Binding) :
    List Binding -> Env
  | [] => []
  | .staticAssign name expr :: bindings =>
      (name, .thunk baseEnv allBindings expr) :: letThunkEntriesGo baseEnv allBindings bindings
  | .dynamicAssign _ _ :: bindings => letThunkEntriesGo baseEnv allBindings bindings

partial def evalStaticPath (path : List AttrPathPart) : M (List String) :=
  match staticPath? path with
  | some [] => throw "eval error: empty attribute path"
  | some names => pure names
  | none => unsupported "dynamic attribute path evaluation"

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

def evaluate (expr : Expr) : M Value :=
  eval defaultFuel [] [] expr

end Eval

def eval (expr : Expr) : Except String Eval.Value :=
  Eval.evaluate expr

end Core
end NixParserLean
