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

private def validateStaticBindingNames (context : String) (bindings : List Binding) :
    Except String Unit :=
  match findDuplicateString? [] (staticBindingNames bindings) with
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

mutual
partial def validateExpr : Expr -> Except String Unit
  | .int _ | .float _ | .bool _ | .null | .ident _ | .path _ => pure ()
  | .str parts => validateStringParts parts
  | .list items => validateExprs items
  | .attrset _ bindings => do
      validateStaticBindingNames "attribute set" bindings
      validateBindings bindings
  | .letIn bindings body => do
      validateStaticBindingNames "let expression" bindings
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
      validateNonemptyPath "selection" path
      validateAttrPathParts path
  | .select base path (some defaultExpr) => do
      validateExpr base
      validateNonemptyPath "selection" path
      validateAttrPathParts path
      validateExpr defaultExpr
  | .hasAttr base path => do
      validateExpr base
      validateNonemptyPath "attribute existence test" path
      validateAttrPathParts path
  | .app function argument => do
      validateExpr function
      validateExpr argument
  | .unary _ expr => validateExpr expr
  | .binary _ left right => do
      validateExpr left
      validateExpr right

partial def validateExprs : List Expr -> Except String Unit
  | [] => pure ()
  | expr :: exprs => do
      validateExpr expr
      validateExprs exprs

partial def validateStringParts : List StringPart -> Except String Unit
  | [] => pure ()
  | .text _ :: parts => validateStringParts parts
  | .interpolation expr :: parts => do
      validateExpr expr
      validateStringParts parts

partial def validateAttrPathPart : AttrPathPart -> Except String Unit
  | .static _ => pure ()
  | .dynamicString parts => validateStringParts parts

partial def validateAttrPathParts : List AttrPathPart -> Except String Unit
  | [] => pure ()
  | part :: parts => do
      validateAttrPathPart part
      validateAttrPathParts parts

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

partial def validateBinding : Binding -> Except String Unit
  | .staticAssign _ value => validateExpr value
  | .inheritAssign _ => pure ()
  | .dynamicAssign path value => do
      validateNonemptyPath "dynamic binding" path
      validateAttrPathParts path
      validateExpr value

partial def validateBindings : List Binding -> Except String Unit
  | [] => pure ()
  | binding :: bindings => do
      validateBinding binding
      validateBindings bindings
end

def validate (expr : Expr) : Except String Unit :=
  validateExpr expr

end Core
end NixParserLean
