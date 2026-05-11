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

def defaultValidationFuel : Nat := 100000

mutual
def validateExprFuel : Nat -> Expr -> Except String Unit
  | 0, _ => throw "semantic error: validation fuel exhausted"
  | fuel + 1, expr =>
    match expr with
    | .int _ | .float _ | .bool _ | .null | .ident _ | .path _ => pure ()
    | .str parts => validateStringPartsFuel fuel parts
    | .list items => validateExprsFuel fuel items
    | .attrset _ bindings => do
      validateBindingPaths "attribute set" bindings
      validateBindingsFuel fuel bindings
    | .letIn bindings body => do
      validateBindingPaths "let expression" bindings
      validateBindingsFuel fuel bindings
      validateExprFuel fuel body
    | .lambda param body => do
      validateLambdaParamFuel fuel param
      validateExprFuel fuel body
    | .ifThenElse condition thenBranch elseBranch => do
      validateExprFuel fuel condition
      validateExprFuel fuel thenBranch
      validateExprFuel fuel elseBranch
    | .assertExpr condition body => do
      validateExprFuel fuel condition
      validateExprFuel fuel body
    | .withExpr scope body => do
      validateExprFuel fuel scope
      validateExprFuel fuel body
    | .select base path none => do
      validateExprFuel fuel base
      validateExprsFuel fuel path.exprs
    | .select base path (some defaultExpr) => do
      validateExprFuel fuel base
      validateExprsFuel fuel path.exprs
      validateExprFuel fuel defaultExpr
    | .hasAttr base path => do
      validateExprFuel fuel base
      validateExprsFuel fuel path.exprs
    | .app function argument => do
      validateExprFuel fuel function
      validateExprFuel fuel argument
    | .unary _ expr => validateExprFuel fuel expr
    | .binary _ left right => do
      validateExprFuel fuel left
      validateExprFuel fuel right

def validateExprsFuel : Nat -> List Expr -> Except String Unit
  | _, [] => pure ()
  | 0, _ :: _ => throw "semantic error: validation fuel exhausted"
  | fuel + 1, x :: xs => do
      validateExprFuel fuel x
      validateExprsFuel fuel xs

def validateStringPartsFuel : Nat -> List StringPart -> Except String Unit
  | _, [] => pure ()
  | 0, _ :: _ => throw "semantic error: validation fuel exhausted"
  | fuel + 1, .text _ :: parts => validateStringPartsFuel fuel parts
  | fuel + 1, .interpolation expr :: parts => do
      validateExprFuel fuel expr
      validateStringPartsFuel fuel parts

def validateLambdaParamFuel : Nat -> LambdaParam -> Except String Unit
  | 0, _ => throw "semantic error: validation fuel exhausted"
  | _ + 1, .ident _ => pure ()
  | fuel + 1, .attrset paramSet => validateParamEntriesFuel fuel paramSet.entries
  | fuel + 1, .alias name (.attrset paramSet) => do
      validateParamEntriesFuel fuel paramSet.entries
      validateParamAliasName name paramSet.entries
  | fuel + 1, .alias _ param => validateLambdaParamFuel fuel param

def validateParamEntriesFuel (fuel : Nat) (entries : List ParamEntry) : Except String Unit := do
      validateParamEntryNames entries
      validateParamEntryDefaultsFuel fuel entries

def validateParamEntryDefaultsFuel : Nat -> List ParamEntry -> Except String Unit
  | _, [] => pure ()
  | 0, _ :: _ => throw "semantic error: validation fuel exhausted"
  | fuel + 1, entry :: entries => do
      match entry.default? with
      | none => pure ()
      | some expr => validateExprFuel fuel expr
      validateParamEntryDefaultsFuel fuel entries

def validateBindingsFuel : Nat -> List Binding -> Except String Unit
  | _, [] => pure ()
  | 0, _ :: _ => throw "semantic error: validation fuel exhausted"
  | fuel + 1, binding :: bindings => do
      validateExprsFuel fuel (bindingValues binding)
      match binding with
      | .assign path _ => validateExprsFuel fuel path.exprs
      | .inherit _ | .inheritFrom _ _ => pure ()
      validateBindingsFuel fuel bindings
end

def validateExpr (expr : Expr) : Except String Unit :=
  validateExprFuel defaultValidationFuel expr

def validate (expr : Expr) : Except String Unit :=
  validateExpr expr

end NixParserLean
