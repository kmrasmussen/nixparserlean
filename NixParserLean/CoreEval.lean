import NixParserLean.Core

namespace NixParserLean
namespace Core
namespace Eval

inductive Value where
  | int : Int -> Value
  | str : String -> Value
  | bool : Bool -> Value
  | null : Value
  | list : List Value -> Value
  | attrset : List (String × Value) -> Value
  deriving Repr, BEq, Inhabited

abbrev Env := List (String × Value)
abbrev M := Except String

private def unsupported (feature : String) : M α :=
  throw s!"eval error: unsupported {feature}"

private def lookupName (name : String) : Env -> M Value
  | [] => throw s!"eval error: unbound identifier '{name}'"
  | (candidate, value) :: rest =>
      if candidate == name then pure value else lookupName name rest

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
partial def eval (env : Env) : Expr -> M Value
  | .int value => pure (.int value)
  | .str parts =>
      match textOnlyString parts with
      | some text => pure (.str text)
      | none => unsupported "string interpolation evaluation"
  | .bool value => pure (.bool value)
  | .null => pure .null
  | .ident name => lookupName name env
  | .path _ => unsupported "path values"
  | .list items => do
      pure (.list (← evalList env items))
  | .attrset recursive bindings => do
      if recursive then
        unsupported "recursive attribute sets"
      else
        pure (.attrset (← evalBindings env bindings))
  | .letIn bindings body => do
      let values ← evalBindings env bindings
      eval (values ++ env) body
  | .lambda _ _ => unsupported "lambda evaluation"
  | .ifThenElse condition thenBranch elseBranch => do
      match ← eval env condition with
      | .bool true => eval env thenBranch
      | .bool false => eval env elseBranch
      | _ => throw "eval error: if condition must be a bool"
  | .assertExpr condition body => do
      match ← eval env condition with
      | .bool true => eval env body
      | .bool false => throw "eval error: assertion failed"
      | _ => throw "eval error: assertion condition must be a bool"
  | .withExpr _ _ => unsupported "with evaluation"
  | .select base path none => do
      let names ← evalStaticPath path
      selectPath (← eval env base) names
  | .select base path (some defaultExpr) => do
      let names ← evalStaticPath path
      match selectPath? (← eval env base) names with
      | some value => pure value
      | none => eval env defaultExpr
  | .hasAttr base path => do
      let names ← evalStaticPath path
      pure (.bool ((selectPath? (← eval env base) names).isSome))
  | .app _ _ => unsupported "function application"
  | .unary op inner => do
      evalUnary op (← eval env inner)
  | .binary op left right => do
      evalBinary op (← eval env left) (← eval env right)

partial def evalList (env : Env) : List Expr -> M (List Value)
  | [] => pure []
  | item :: items => do
      let item ← eval env item
      let items ← evalList env items
      pure (item :: items)

partial def evalBindings (env : Env) : List Binding -> M (List (String × Value))
  | [] => pure []
  | binding :: bindings => do
      let attrs ← evalBindings env bindings
      evalBindingInto env binding attrs

partial def evalBindingInto (env : Env) (binding : Binding) (attrs : List (String × Value)) :
    M (List (String × Value)) := do
  match binding with
  | .staticAssign name expr => do
      let value ← eval env expr
      pure (insertAttr name value attrs)
  | .dynamicAssign _ _ => unsupported "dynamic attribute binding evaluation"

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
  eval [] expr

end Eval

def eval (expr : Expr) : Except String Eval.Value :=
  Eval.evaluate expr

end Core
end NixParserLean
