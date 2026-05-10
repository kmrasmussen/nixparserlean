import NixParserLean.Syntax

namespace NixParserLean

private def namesToPaths : List String -> List AttrPath
  | [] => []
  | name :: names => { parts := [name] } :: namesToPaths names

private def bindingPaths : Binding -> List AttrPath
  | .assign path _ => [path]
  | .inherit names => namesToPaths names
  | .inheritFrom _ names => namesToPaths names

private def bindingValues : Binding -> List Expr
  | .assign _ value => [value]
  | .inherit _ => []
  | .inheritFrom scope _ => [scope]

private def allBindingPaths : List Binding -> List AttrPath
  | [] => []
  | binding :: bindings => bindingPaths binding ++ allBindingPaths bindings

private def isPrefix : List String -> List String -> Bool
  | [], _ => true
  | _ :: _, [] => false
  | x :: xs, y :: ys => x == y && isPrefix xs ys

private def pathsConflict (left right : AttrPath) : Bool :=
  isPrefix left.parts right.parts || isPrefix right.parts left.parts

private def findConflictWith (path : AttrPath) : List AttrPath -> Option (AttrPath × AttrPath)
  | [] => none
  | other :: paths =>
      if pathsConflict other path then
        some (other, path)
      else
        findConflictWith path paths

private def firstPathConflict? (seen : List AttrPath) : List AttrPath ->
    Option (AttrPath × AttrPath)
  | [] => none
  | path :: paths =>
      match findConflictWith path seen with
      | some conflict => some conflict
      | none => firstPathConflict? (path :: seen) paths

private def bindingConflictMessage (context : String) (left right : AttrPath) : String :=
  if left.toString == right.toString then
    s!"semantic error: duplicate binding '{left.toString}' in {context}"
  else
    s!"semantic error: conflicting binding paths '{left.toString}' and '{right.toString}' in {context}"

private def validateBindingPaths (context : String) (bindings : List Binding) :
    Except String Unit := do
  let paths := allBindingPaths bindings
  match firstPathConflict? [] paths with
  | some (left, right) => throw (bindingConflictMessage context left right)
  | none => pure ()

mutual
partial def validateExpr : Expr -> Except String Unit
  | .int _ | .str _ | .bool _ | .null | .ident _ | .path _ => pure ()
  | .list items => validateExprs items
  | .attrset _ bindings => do
      validateBindingPaths "attribute set" bindings
      validateBindings bindings
  | .letIn bindings body => do
      validateBindingPaths "let expression" bindings
      validateBindings bindings
      validateExpr body
  | .lambda _ body => validateExpr body
  | .ifThenElse condition thenBranch elseBranch => do
      validateExpr condition
      validateExpr thenBranch
      validateExpr elseBranch
  | .withExpr scope body => do
      validateExpr scope
      validateExpr body
  | .select base _ => validateExpr base
  | .app function argument => do
      validateExpr function
      validateExpr argument
  | .binary _ left right => do
      validateExpr left
      validateExpr right

partial def validateExprs : List Expr -> Except String Unit
  | [] => pure ()
  | x :: xs => do
      validateExpr x
      validateExprs xs

partial def validateBindings : List Binding -> Except String Unit
  | [] => pure ()
  | binding :: bindings => do
      validateExprs (bindingValues binding)
      validateBindings bindings
end

def validate (expr : Expr) : Except String Unit :=
  validateExpr expr

end NixParserLean
