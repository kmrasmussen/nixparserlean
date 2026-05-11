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

def nestedStaticAssignFromHead (name : String) : List String -> Core.Expr -> Core.Binding
  | [], value => .staticAssign name value
  | next :: names, value =>
      .staticAssign name (.attrset false [nestedStaticAssignFromHead next names value])

def nestedStaticAssign : List String -> Core.Expr -> M Core.Binding
  | [], _ => throw "desugar error: empty attribute path"
  | name :: names, value => pure (nestedStaticAssignFromHead name names value)

def bindingFromPath (path : List Core.AttrPathPart) (value : Core.Expr) :
    M Core.Binding :=
  match staticNames? path with
  | some names => nestedStaticAssign names value
  | none => pure (.dynamicAssign path value)

def bindingStaticName? : Core.Binding -> Option String
  | .staticAssign name _ => some name
  | .inheritAssign name => some name
  | .dynamicAssign _ _ => none

def staticBindingNames : List Core.Binding -> List String
  | [] => []
  | .staticAssign name _ :: bindings => name :: staticBindingNames bindings
  | .inheritAssign name :: bindings => name :: staticBindingNames bindings
  | .dynamicAssign _ _ :: bindings => staticBindingNames bindings

theorem bindingFromPath_static_top_name
    {path : List Core.AttrPathPart} {value : Core.Expr} {name : String} {names : List String}
    (h : staticNames? path = some (name :: names)) :
    (bindingFromPath path value).map bindingStaticName? = .ok (some name) := by
  unfold bindingFromPath
  rw [h]
  cases names with
  | nil => rfl
  | cons next rest => rfl

theorem bindingFromPath_static_nested_tail
    {path : List Core.AttrPathPart} {value : Core.Expr}
    {name next : String} {names : List String}
    (h : staticNames? path = some (name :: next :: names)) :
    bindingFromPath path value =
      .ok (.staticAssign name (.attrset false [nestedStaticAssignFromHead next names value])) := by
  unfold bindingFromPath
  rw [h]
  rfl

theorem bindingFromPath_empty_static_rejected {path : List Core.AttrPathPart}
    {value : Core.Expr} (h : staticNames? path = some []) :
    bindingFromPath path value = .error "desugar error: empty attribute path" := by
  unfold bindingFromPath
  rw [h]
  rfl

def inheritBindings : List String -> List Core.Binding
  | [] => []
  | name :: names => .inheritAssign name :: inheritBindings names

def inheritFromBindings (scope : Core.Expr) : List String -> List Core.Binding
  | [] => []
  | name :: names =>
      let selected := Core.Expr.select scope [.static name] none
      .staticAssign name selected :: inheritFromBindings scope names

def staticAttrPath? (path : List Core.AttrPathPart) : Bool :=
  match staticNames? path with
  | some (_ :: _) => true
  | _ => false

-- TODO theorem: for static non-empty paths, the selection-default lowering
-- below preserves evaluator results relative to Core.Expr.select with default.

mutual
def mergeStaticAttrsetsFuel : Nat -> Core.Expr -> Core.Expr -> Option Core.Expr
  | 0, _, _ => none
  | fuel + 1, .attrset false leftBindings, .attrset false rightBindings =>
      some (.attrset false (mergeBindingsFuel fuel leftBindings rightBindings))
  | _, _, _ => none

def mergeBindingIntoFuel : Nat -> Core.Binding -> List Core.Binding -> List Core.Binding
  | 0, binding, bindings => binding :: bindings
  | _ + 1, binding, [] => [binding]
  | fuel + 1, binding, existing :: rest =>
      match binding, existing with
      | .staticAssign name value, .staticAssign existingName existingValue =>
          if name == existingName then
            match mergeStaticAttrsetsFuel fuel value existingValue with
            | some value => .staticAssign name value :: rest
            | none => binding :: existing :: rest
          else
            existing :: mergeBindingIntoFuel fuel binding rest
      | .inheritAssign name, .staticAssign existingName _
      | .staticAssign name _, .inheritAssign existingName
      | .inheritAssign name, .inheritAssign existingName =>
          if name == existingName then
            binding :: existing :: rest
          else
            existing :: mergeBindingIntoFuel fuel binding rest
      | _, _ => existing :: mergeBindingIntoFuel fuel binding rest

def mergeBindingsFuel : Nat -> List Core.Binding -> List Core.Binding -> List Core.Binding
  | 0, bindings, into => bindings ++ into
  | _ + 1, [], into => into
  | fuel + 1, binding :: bindings, into =>
      mergeBindingsFuel fuel bindings (mergeBindingIntoFuel fuel binding into)
end

def mergeFuel : Nat := 100000

def mergeStaticAttrsets (left right : Core.Expr) : Option Core.Expr :=
  mergeStaticAttrsetsFuel mergeFuel left right

def mergeBindingInto (binding : Core.Binding) (bindings : List Core.Binding) :
    List Core.Binding :=
  mergeBindingIntoFuel mergeFuel binding bindings

def mergeBindings (bindings into : List Core.Binding) : List Core.Binding :=
  mergeBindingsFuel mergeFuel bindings into

theorem mergeBindingInto_static_attrset_collision_preserves_single_name
    {name : String} {leftBindings rightBindings : List Core.Binding} :
    staticBindingNames
      (mergeBindingInto
        (.staticAssign name (.attrset false leftBindings))
        [.staticAssign name (.attrset false rightBindings)]) =
      [name] := by
  simp [mergeBindingInto, mergeFuel, mergeBindingIntoFuel, mergeStaticAttrsetsFuel,
    staticBindingNames]

theorem mergeBindingIntoFuel_static_unmergeable_collision_exposes_duplicate_name
    {fuel : Nat} {name : String} {left right : Core.Expr}
    (h : mergeStaticAttrsetsFuel fuel left right = none) :
    staticBindingNames
      (mergeBindingIntoFuel (fuel + 1) (.staticAssign name left)
        [.staticAssign name right]) =
      [name, name] := by
  simp [mergeBindingIntoFuel, h, staticBindingNames]

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
      let base ← expr base
      let path ← attrPathParts path.parts
      let default? ←
        match default? with
        | none => pure none
        | some defaultExpr => pure (some (← expr defaultExpr))
      match default? with
      | some defaultExpr =>
          if staticAttrPath? path then
            -- Static defaults lower away from the core select-default branch.
            pure (.ifThenElse (.hasAttr base path) (.select base path none) defaultExpr)
          else
            pure (.select base path (some defaultExpr))
      | none => pure (.select base path none)
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
      pure [← bindingFromPath (← attrPathParts path.parts) value]
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
