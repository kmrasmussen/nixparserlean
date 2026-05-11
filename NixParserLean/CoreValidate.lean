import NixParserLean.Core

namespace NixParserLean
namespace Core

private def findDuplicateString? (seen : List String) : List String -> Option String
  | [] => none
  | name :: names =>
      if seen.contains name then
        some name
      else
        findDuplicateString? (name :: seen) names

private def staticBindingNames : List Binding -> List String
  | [] => []
  | .staticAssign name _ :: bindings => name :: staticBindingNames bindings
  | .inheritAssign name :: bindings => name :: staticBindingNames bindings
  | .dynamicAssign _ _ :: bindings => staticBindingNames bindings

private def containsEmptyString : List String -> Bool
  | [] => false
  | name :: names => name == "" || containsEmptyString names

private def validateStaticBindingNames (context : String) (bindings : List Binding) :
    Except String Unit :=
  let names := staticBindingNames bindings
  if containsEmptyString names then
    throw s!"core error: empty static binding name in {context}"
  else
    match findDuplicateString? [] names with
    | some name => throw s!"core error: duplicate static binding '{name}' in {context}"
    | none => pure ()

private def validateNonemptyPath (context : String) : List AttrPathPart -> Except String Unit
  | [] => throw s!"core error: empty attribute path in {context}"
  | _ :: _ => pure ()

private def paramEntryNames : List ParamEntry -> List String
  | [] => []
  | entry :: entries => entry.name :: paramEntryNames entries

private def validateParamEntryNames (entries : List ParamEntry) : Except String Unit :=
  match findDuplicateString? [] (paramEntryNames entries) with
  | some name => throw s!"core error: duplicate lambda parameter '{name}'"
  | none => pure ()

private def validateParamAliasName (aliasName : String) (entries : List ParamEntry) :
    Except String Unit :=
  if (paramEntryNames entries).contains aliasName then
    throw s!"core error: lambda alias '{aliasName}' conflicts with parameter entry"
  else
    pure ()

def defaultValidationFuel : Nat := 100000

mutual
def validateExprFuel : Nat -> Expr -> Except String Unit
  | 0, _ => throw "core error: validation fuel exhausted"
  | fuel + 1, expr =>
    match expr with
    | .int _ | .float _ | .bool _ | .null | .ident _ | .path _ => pure ()
    | .str parts => validateStringPartsFuel fuel parts
    | .list items => validateExprsFuel fuel items
    | .attrset _ bindings => do
      validateStaticBindingNames "attribute set" bindings
      validateBindingsFuel fuel bindings
    | .letIn bindings body => do
      validateStaticBindingNames "let expression" bindings
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
      validateNonemptyPath "selection" path
      validateAttrPathPartsFuel fuel path
    | .select base path (some defaultExpr) => do
      validateExprFuel fuel base
      validateNonemptyPath "selection" path
      validateAttrPathPartsFuel fuel path
      validateExprFuel fuel defaultExpr
    | .hasAttr base path => do
      validateExprFuel fuel base
      validateNonemptyPath "attribute existence test" path
      validateAttrPathPartsFuel fuel path
    | .app function argument => do
      validateExprFuel fuel function
      validateExprFuel fuel argument
    | .unary _ expr => validateExprFuel fuel expr
    | .binary _ left right => do
      validateExprFuel fuel left
      validateExprFuel fuel right

def validateExprsFuel : Nat -> List Expr -> Except String Unit
  | _, [] => pure ()
  | 0, _ :: _ => throw "core error: validation fuel exhausted"
  | fuel + 1, expr :: exprs => do
      validateExprFuel fuel expr
      validateExprsFuel fuel exprs

def validateStringPartsFuel : Nat -> List StringPart -> Except String Unit
  | _, [] => pure ()
  | 0, _ :: _ => throw "core error: validation fuel exhausted"
  | fuel + 1, .text _ :: parts => validateStringPartsFuel fuel parts
  | fuel + 1, .interpolation expr :: parts => do
      validateExprFuel fuel expr
      validateStringPartsFuel fuel parts

def validateAttrPathPartFuel : Nat -> AttrPathPart -> Except String Unit
  | 0, _ => throw "core error: validation fuel exhausted"
  | _ + 1, .static _ => pure ()
  | fuel + 1, .dynamicString parts => validateStringPartsFuel fuel parts

def validateAttrPathPartsFuel : Nat -> List AttrPathPart -> Except String Unit
  | _, [] => pure ()
  | 0, _ :: _ => throw "core error: validation fuel exhausted"
  | fuel + 1, part :: parts => do
      validateAttrPathPartFuel fuel part
      validateAttrPathPartsFuel fuel parts

def validateLambdaParamFuel : Nat -> LambdaParam -> Except String Unit
  | 0, _ => throw "core error: validation fuel exhausted"
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
  | 0, _ :: _ => throw "core error: validation fuel exhausted"
  | fuel + 1, entry :: entries => do
      match entry.default? with
      | none => pure ()
      | some expr => validateExprFuel fuel expr
      validateParamEntryDefaultsFuel fuel entries

def validateBindingFuel : Nat -> Binding -> Except String Unit
  | 0, _ => throw "core error: validation fuel exhausted"
  | fuel + 1, .staticAssign _ value => validateExprFuel fuel value
  | _ + 1, .inheritAssign _ => pure ()
  | fuel + 1, .dynamicAssign path value => do
      validateNonemptyPath "dynamic binding" path
      validateAttrPathPartsFuel fuel path
      validateExprFuel fuel value

def validateBindingsFuel : Nat -> List Binding -> Except String Unit
  | _, [] => pure ()
  | 0, _ :: _ => throw "core error: validation fuel exhausted"
  | fuel + 1, binding :: bindings => do
      validateBindingFuel fuel binding
      validateBindingsFuel fuel bindings
end

def validateExpr (expr : Expr) : Except String Unit :=
  validateExprFuel defaultValidationFuel expr

def validate (expr : Expr) : Except String Unit :=
  validateExpr expr

theorem validate_single_static_null_attrset_of_nonempty {name : String}
    (h : (name == "") = false) :
    validate (.attrset false [.staticAssign name .null]) = .ok () := by
  unfold validate validateExpr validateExprFuel validateStaticBindingNames
  unfold staticBindingNames containsEmptyString findDuplicateString?
  unfold validateBindingsFuel validateBindingFuel
  simp [defaultValidationFuel, h, staticBindingNames, containsEmptyString,
    findDuplicateString?, validateExprFuel, validateBindingsFuel]
  rfl

end Core
end NixParserLean
