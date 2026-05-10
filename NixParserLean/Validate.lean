import NixParserLean.Syntax

namespace NixParserLean

private def containsString : List String -> String -> Bool
  | [], _ => false
  | x :: xs, needle => x == needle || containsString xs needle

private def firstDuplicate? (seen : List String) : List String -> Option String
  | [] => none
  | x :: xs =>
      if containsString seen x then
        some x
      else
        firstDuplicate? (x :: seen) xs

private def bindingNames : Binding -> List String
  | .assign path _ => [path.toString]
  | .inherit names => names
  | .inheritFrom _ names => names

private def bindingValues : Binding -> List Expr
  | .assign _ value => [value]
  | .inherit _ => []
  | .inheritFrom scope _ => [scope]

private def allBindingNames : List Binding -> List String
  | [] => []
  | binding :: bindings => bindingNames binding ++ allBindingNames bindings

private def validateDuplicateBindings (context : String) (bindings : List Binding) :
    Except String Unit := do
  let names := allBindingNames bindings
  match firstDuplicate? [] names with
  | some name => throw s!"semantic error: duplicate binding '{name}' in {context}"
  | none => pure ()

mutual
partial def validateExpr : Expr -> Except String Unit
  | .int _ | .str _ | .bool _ | .null | .ident _ | .path _ => pure ()
  | .list items => validateExprs items
  | .attrset _ bindings => do
      validateDuplicateBindings "attribute set" bindings
      validateBindings bindings
  | .letIn bindings body => do
      validateDuplicateBindings "let expression" bindings
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
