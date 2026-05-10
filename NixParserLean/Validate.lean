import NixParserLean.Syntax

namespace NixParserLean

private def namesToPaths : List String -> List AttrPath
  | [] => []
  | name :: names => { parts := [.static name] } :: namesToPaths names

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

private def staticPartNames? : List AttrPathPart -> Option (List String)
  | [] => some []
  | .static name :: parts => do
      let names ← staticPartNames? parts
      some (name :: names)
  | .dynamicString _ :: _ => none

private def AttrPath.staticParts? (path : AttrPath) : Option (List String) :=
  staticPartNames? path.parts

private def pathsConflict (left right : AttrPath) : Bool :=
  match left.staticParts?, right.staticParts? with
  | some leftParts, some rightParts =>
      isPrefix leftParts rightParts || isPrefix rightParts leftParts
  | _, _ => false

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

private def findDuplicateString? (seen : List String) : List String -> Option String
  | [] => none
  | name :: names =>
      if seen.contains name then
        some name
      else
        findDuplicateString? (name :: seen) names

private def paramEntryNames : List ParamEntry -> List String
  | [] => []
  | entry :: entries => entry.name :: paramEntryNames entries

private def validateParamEntryNames (entries : List ParamEntry) : Except String Unit :=
  match findDuplicateString? [] (paramEntryNames entries) with
  | some name => throw s!"semantic error: duplicate lambda parameter '{name}'"
  | none => pure ()

private def validateParamAliasName (aliasName : String) (entries : List ParamEntry) :
    Except String Unit :=
  if (paramEntryNames entries).contains aliasName then
    throw s!"semantic error: lambda alias '{aliasName}' conflicts with parameter entry"
  else
    pure ()

private def stringPartExprs : List StringPart -> List Expr
  | [] => []
  | .text _ :: parts => stringPartExprs parts
  | .interpolation expr :: parts => expr :: stringPartExprs parts

private def attrPathPartExprs : AttrPathPart -> List Expr
  | .static _ => []
  | .dynamicString parts => stringPartExprs parts

private def attrPathExprs : List AttrPathPart -> List Expr
  | [] => []
  | part :: parts => attrPathPartExprs part ++ attrPathExprs parts

private def AttrPath.exprs (path : AttrPath) : List Expr :=
  attrPathExprs path.parts

mutual
partial def validateExpr : Expr -> Except String Unit
  | .int _ | .float _ | .bool _ | .null | .ident _ | .path _ => pure ()
  | .str parts => validateStringParts parts
  | .list items => validateExprs items
  | .attrset _ bindings => do
      validateBindingPaths "attribute set" bindings
      validateBindings bindings
  | .letIn bindings body => do
      validateBindingPaths "let expression" bindings
      validateBindings bindings
      validateExpr body
  | .lambda param body => do
      validateLambdaParam param
      validateExpr body
  | .ifThenElse condition thenBranch elseBranch => do
      validateExpr condition
      validateExpr thenBranch
      validateExpr elseBranch
  | .assertExpr condition body => do
      validateExpr condition
      validateExpr body
  | .withExpr scope body => do
      validateExpr scope
      validateExpr body
  | .select base path none => do
      validateExpr base
      validateExprs path.exprs
  | .select base path (some defaultExpr) => do
      validateExpr base
      validateExprs path.exprs
      validateExpr defaultExpr
  | .hasAttr base path => do
      validateExpr base
      validateExprs path.exprs
  | .app function argument => do
      validateExpr function
      validateExpr argument
  | .unary _ expr => validateExpr expr
  | .binary _ left right => do
      validateExpr left
      validateExpr right

partial def validateExprs : List Expr -> Except String Unit
  | [] => pure ()
  | x :: xs => do
      validateExpr x
      validateExprs xs

partial def validateStringParts : List StringPart -> Except String Unit
  | [] => pure ()
  | .text _ :: parts => validateStringParts parts
  | .interpolation expr :: parts => do
      validateExpr expr
      validateStringParts parts

partial def validateLambdaParam : LambdaParam -> Except String Unit
  | .ident _ => pure ()
  | .attrset paramSet => validateParamEntries paramSet.entries
  | .alias name (.attrset paramSet) => do
      validateParamEntries paramSet.entries
      validateParamAliasName name paramSet.entries
  | .alias _ param => validateLambdaParam param

partial def validateParamEntries : List ParamEntry -> Except String Unit
  | entries => do
      validateParamEntryNames entries
      validateParamEntryDefaults entries

partial def validateParamEntryDefaults : List ParamEntry -> Except String Unit
  | [] => pure ()
  | entry :: entries => do
      match entry.default? with
      | none => pure ()
      | some expr => validateExpr expr
      validateParamEntryDefaults entries

partial def validateBindings : List Binding -> Except String Unit
  | [] => pure ()
  | binding :: bindings => do
      validateExprs (bindingValues binding)
      match binding with
      | .assign path _ => validateExprs path.exprs
      | .inherit _ | .inheritFrom _ _ => pure ()
      validateBindings bindings
end

def validate (expr : Expr) : Except String Unit :=
  validateExpr expr

end NixParserLean
