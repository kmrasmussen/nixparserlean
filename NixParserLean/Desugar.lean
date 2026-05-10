import NixParserLean.Core
import NixParserLean.Syntax

namespace NixParserLean

namespace Desugar

abbrev M := Except String

def staticNames? : List Core.AttrPathPart -> Option (List String)
  | [] => some []
  | .static name :: parts => do
      let names ← staticNames? parts
      some (name :: names)
  | .dynamicString _ :: _ => none

def nestedStaticAssign : List String -> Core.Expr -> Core.Binding
  | [], value => .dynamicAssign [] value
  | [name], value => .staticAssign name value
  | name :: names, value =>
      .staticAssign name (.attrset false [nestedStaticAssign names value])

def bindingFromPath (path : List Core.AttrPathPart) (value : Core.Expr) :
    Core.Binding :=
  match staticNames? path with
  | some names => nestedStaticAssign names value
  | none => .dynamicAssign path value

def bindingStaticName? : Core.Binding -> Option String
  | .staticAssign name _ => some name
  | .inheritAssign name => some name
  | .dynamicAssign _ _ => none

theorem bindingFromPath_static_top_name
    {path : List Core.AttrPathPart} {value : Core.Expr} {name : String} {names : List String}
    (h : staticNames? path = some (name :: names)) :
    bindingStaticName? (bindingFromPath path value) = some name := by
  unfold bindingFromPath
  rw [h]
  cases names with
  | nil => simp [nestedStaticAssign, bindingStaticName?]
  | cons next rest => simp [nestedStaticAssign, bindingStaticName?]

theorem bindingFromPath_static_nested_tail
    {path : List Core.AttrPathPart} {value : Core.Expr}
    {name next : String} {names : List String}
    (h : staticNames? path = some (name :: next :: names)) :
    bindingFromPath path value =
      .staticAssign name (.attrset false [nestedStaticAssign (next :: names) value]) := by
  unfold bindingFromPath
  rw [h]
  rfl

partial def inheritBindings : List String -> List Core.Binding
  | [] => []
  | name :: names => .inheritAssign name :: inheritBindings names

partial def inheritFromBindings (scope : Core.Expr) : List String -> List Core.Binding
  | [] => []
  | name :: names =>
      let selected := Core.Expr.select scope [.static name] none
      .staticAssign name selected :: inheritFromBindings scope names

mutual
partial def mergeStaticAttrsets (left right : Core.Expr) : Option Core.Expr :=
  match left, right with
  | .attrset false leftBindings, .attrset false rightBindings =>
      some (.attrset false (mergeBindings leftBindings rightBindings))
  | _, _ => none

partial def mergeBindingInto (binding : Core.Binding) : List Core.Binding -> List Core.Binding
  | [] => [binding]
  | existing :: rest =>
      match binding, existing with
      | .staticAssign name value, .staticAssign existingName existingValue =>
          if name == existingName then
            match mergeStaticAttrsets value existingValue with
            | some value => .staticAssign name value :: rest
            | none => binding :: existing :: rest
          else
            existing :: mergeBindingInto binding rest
      | .inheritAssign name, .staticAssign existingName _
      | .staticAssign name _, .inheritAssign existingName
      | .inheritAssign name, .inheritAssign existingName =>
          if name == existingName then
            binding :: existing :: rest
          else
            existing :: mergeBindingInto binding rest
      | _, _ => existing :: mergeBindingInto binding rest

partial def mergeBindings : List Core.Binding -> List Core.Binding -> List Core.Binding
  | [], into => into
  | binding :: bindings, into => mergeBindings bindings (mergeBindingInto binding into)
end

mutual
partial def stringParts : List StringPart -> M (List Core.StringPart)
  | [] => pure []
  | .text text :: parts => do
      let rest ← stringParts parts
      pure (.text text :: rest)
  | .interpolation surfaceExpr :: parts => do
      let expr ← expr surfaceExpr
      let rest ← stringParts parts
      pure (.interpolation expr :: rest)

partial def attrPathPart : AttrPathPart -> M Core.AttrPathPart
  | .static name => pure (.static name)
  | .dynamicString parts => do
      pure (.dynamicString (← stringParts parts))

partial def attrPathParts : List AttrPathPart -> M (List Core.AttrPathPart)
  | [] => pure []
  | part :: parts => do
      let part ← attrPathPart part
      let parts ← attrPathParts parts
      pure (part :: parts)

partial def lambdaParam : LambdaParam -> M Core.LambdaParam
  | .ident name => pure (.ident name)
  | .attrset paramSet => do
      pure (.attrset { paramSet with entries := (← paramEntries paramSet.entries) })
  | .alias name param => do
      pure (.alias name (← lambdaParam param))

partial def paramEntries : List ParamEntry -> M (List Core.ParamEntry)
  | [] => pure []
  | entry :: entries => do
      let default? ←
        match entry.default? with
        | none => pure none
        | some defaultExpr => pure (some (← expr defaultExpr))
      let entries ← paramEntries entries
      pure ({ name := entry.name, default? } :: entries)

partial def expr : Expr -> M Core.Expr
  | .int value => pure (.int value)
  | .float value => pure (.float value)
  | .str parts => do
      pure (.str (← stringParts parts))
  | .bool value => pure (.bool value)
  | .null => pure .null
  | .ident name => pure (.ident name)
  | .path path => pure (.path path)
  | .list items => do
      pure (.list (← exprs items))
  | .attrset recursive surfaceBindings => do
      pure (.attrset recursive (← bindings surfaceBindings))
  | .letIn surfaceBindings body => do
      pure (.letIn (← bindings surfaceBindings) (← expr body))
  | .lambda param body => do
      pure (.lambda (← lambdaParam param) (← expr body))
  | .ifThenElse condition thenBranch elseBranch => do
      pure (.ifThenElse (← expr condition) (← expr thenBranch) (← expr elseBranch))
  | .assertExpr condition body => do
      pure (.assertExpr (← expr condition) (← expr body))
  | .withExpr scope body => do
      pure (.withExpr (← expr scope) (← expr body))
  | .select base path default? => do
      let default? ←
        match default? with
        | none => pure none
        | some defaultExpr => pure (some (← expr defaultExpr))
      pure (.select (← expr base) (← attrPathParts path.parts) default?)
  | .hasAttr base path => do
      pure (.hasAttr (← expr base) (← attrPathParts path.parts))
  | .app function argument => do
      pure (.app (← expr function) (← expr argument))
  | .unary op inner => do
      pure (.unary op (← expr inner))
  | .binary op left right => do
      pure (.binary op (← expr left) (← expr right))

partial def exprs : List Expr -> M (List Core.Expr)
  | [] => pure []
  | item :: items => do
      let item ← expr item
      let items ← exprs items
      pure (item :: items)

partial def binding : Binding -> M (List Core.Binding)
  | .assign path value => do
      let value ← expr value
      pure [bindingFromPath (← attrPathParts path.parts) value]
  | .inherit names => pure (inheritBindings names)
  | .inheritFrom scope names => do
      let scope ← expr scope
      pure (inheritFromBindings scope names)

partial def bindings : List Binding -> M (List Core.Binding)
  | [] => pure []
  | surfaceBinding :: rest => do
      let binding ← binding surfaceBinding
      let rest ← bindings rest
      pure (mergeBindings binding rest)
end

def exprToCore (surface : Expr) : M Core.Expr :=
  expr surface

end Desugar

def desugar (surface : Expr) : Except String Core.Expr :=
  Desugar.exprToCore surface

end NixParserLean
