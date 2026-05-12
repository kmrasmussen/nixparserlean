import NixParserLean.Core
import NixParserLean.CoreValidate
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

theorem bindingFromPath_single_static_null_core_valid {name : String}
    (h : (name == "") = false) :
    (bindingFromPath [.static name] .null).bind
      (fun binding => Core.validate (.attrset false [binding])) = .ok () := by
  unfold bindingFromPath staticNames? nestedStaticAssign nestedStaticAssignFromHead
  change Core.validate (.attrset false [.staticAssign name .null]) = .ok ()
  exact Core.validate_single_static_null_attrset_of_nonempty h

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

def lowerSelectDefault (base : Core.Expr) (path : List Core.AttrPathPart)
    (defaultExpr : Core.Expr) : Core.Expr :=
  if staticAttrPath? path then
    .ifThenElse (.hasAttr base path) (.select base path none) defaultExpr
  else
    .select base path (some defaultExpr)

theorem lowerSelectDefault_static_nonempty_selection_default_shape
    {base defaultExpr : Core.Expr} {path : List Core.AttrPathPart}
    (hStatic : staticAttrPath? path = true) :
    lowerSelectDefault base path defaultExpr =
      .ifThenElse (.hasAttr base path) (.select base path none) defaultExpr := by
  unfold lowerSelectDefault
  rw [hStatic]
  simp

def defaultDesugarFuel : Nat := 100000

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
def stringPartsFuel : Nat -> List StringPart -> M (List Core.StringPart)
  | _, [] => pure []
  | 0, _ :: _ => throw "desugar error: fuel exhausted"
  | fuel + 1, .text text :: parts => do
      let rest ← stringPartsFuel fuel parts
      pure (.text text :: rest)
  | fuel + 1, .interpolation surfaceExpr :: parts => do
      let expr ← exprFuel fuel surfaceExpr
      let rest ← stringPartsFuel fuel parts
      pure (.interpolation expr :: rest)

def attrPathPartFuel : Nat -> AttrPathPart -> M Core.AttrPathPart
  | 0, _ => throw "desugar error: fuel exhausted"
  | _ + 1, .static name => pure (.static name)
  | fuel + 1, .dynamicString parts => do
      pure (.dynamicString (← stringPartsFuel fuel parts))

def attrPathPartsFuel : Nat -> List AttrPathPart -> M (List Core.AttrPathPart)
  | _, [] => pure []
  | 0, _ :: _ => throw "desugar error: fuel exhausted"
  | fuel + 1, part :: parts => do
      let part ← attrPathPartFuel fuel part
      let parts ← attrPathPartsFuel fuel parts
      pure (part :: parts)

def lambdaParamFuel : Nat -> LambdaParam -> M Core.LambdaParam
  | 0, _ => throw "desugar error: fuel exhausted"
  | _ + 1, .ident name => pure (.ident name)
  | fuel + 1, .attrset paramSet => do
      pure (.attrset { paramSet with entries := (← paramEntriesFuel fuel paramSet.entries) })
  | fuel + 1, .alias name param => do
      pure (.alias name (← lambdaParamFuel fuel param))

def paramEntriesFuel : Nat -> List ParamEntry -> M (List Core.ParamEntry)
  | _, [] => pure []
  | 0, _ :: _ => throw "desugar error: fuel exhausted"
  | fuel + 1, entry :: entries => do
      let default? ←
        match entry.default? with
        | none => pure none
        | some defaultExpr => pure (some (← exprFuel fuel defaultExpr))
      let entries ← paramEntriesFuel fuel entries
      pure ({ name := entry.name, default? } :: entries)

def exprFuel : Nat -> Expr -> M Core.Expr
  | 0, _ => throw "desugar error: fuel exhausted"
  | _ + 1, .int value => pure (.int value)
  | _ + 1, .float value => pure (.float value)
  | fuel + 1, .str parts => do
      pure (.str (← stringPartsFuel fuel parts))
  | _ + 1, .bool value => pure (.bool value)
  | _ + 1, .null => pure .null
  | _ + 1, .ident name => pure (.ident name)
  | _ + 1, .path path => pure (.path path)
  | fuel + 1, .list items => do
      pure (.list (← exprsFuel fuel items))
  | fuel + 1, .attrset recursive surfaceBindings => do
      pure (.attrset recursive (← bindingsFuel fuel surfaceBindings))
  | fuel + 1, .letIn surfaceBindings body => do
      pure (.letIn (← bindingsFuel fuel surfaceBindings) (← exprFuel fuel body))
  | fuel + 1, .lambda param body => do
      pure (.lambda (← lambdaParamFuel fuel param) (← exprFuel fuel body))
  | fuel + 1, .ifThenElse condition thenBranch elseBranch => do
      pure (.ifThenElse (← exprFuel fuel condition) (← exprFuel fuel thenBranch) (← exprFuel fuel elseBranch))
  | fuel + 1, .assertExpr condition body => do
      pure (.assertExpr (← exprFuel fuel condition) (← exprFuel fuel body))
  | fuel + 1, .withExpr scope body => do
      pure (.withExpr (← exprFuel fuel scope) (← exprFuel fuel body))
  | fuel + 1, .select base path default? => do
      let base ← exprFuel fuel base
      let path ← attrPathPartsFuel fuel path.parts
      let default? ←
        match default? with
        | none => pure none
        | some defaultExpr => pure (some (← exprFuel fuel defaultExpr))
      match default? with
      | some defaultExpr =>
          -- Static defaults lower away from the core select-default branch.
          pure (lowerSelectDefault base path defaultExpr)
      | none => pure (.select base path none)
  | fuel + 1, .hasAttr base path => do
      pure (.hasAttr (← exprFuel fuel base) (← attrPathPartsFuel fuel path.parts))
  | fuel + 1, .app function argument => do
      pure (.app (← exprFuel fuel function) (← exprFuel fuel argument))
  | fuel + 1, .unary op inner => do
      pure (.unary op (← exprFuel fuel inner))
  | fuel + 1, .binary op left right => do
      pure (.binary op (← exprFuel fuel left) (← exprFuel fuel right))

def exprsFuel : Nat -> List Expr -> M (List Core.Expr)
  | _, [] => pure []
  | 0, _ :: _ => throw "desugar error: fuel exhausted"
  | fuel + 1, item :: items => do
      let item ← exprFuel fuel item
      let items ← exprsFuel fuel items
      pure (item :: items)

def bindingFuel : Nat -> Binding -> M (List Core.Binding)
  | 0, _ => throw "desugar error: fuel exhausted"
  | fuel + 1, .assign path value => do
      let value ← exprFuel fuel value
      pure [← bindingFromPath (← attrPathPartsFuel fuel path.parts) value]
  | _ + 1, .inherit names => pure (inheritBindings names)
  | fuel + 1, .inheritFrom scope names => do
      let scope ← exprFuel fuel scope
      pure (inheritFromBindings scope names)

def bindingsFuel : Nat -> List Binding -> M (List Core.Binding)
  | _, [] => pure []
  | 0, _ :: _ => throw "desugar error: fuel exhausted"
  | fuel + 1, surfaceBinding :: rest => do
      let binding ← bindingFuel fuel surfaceBinding
      let rest ← bindingsFuel fuel rest
      pure (mergeBindings binding rest)
end

def stringParts (parts : List StringPart) : M (List Core.StringPart) :=
  stringPartsFuel defaultDesugarFuel parts

def attrPathPart (part : AttrPathPart) : M Core.AttrPathPart :=
  attrPathPartFuel defaultDesugarFuel part

def attrPathParts (parts : List AttrPathPart) : M (List Core.AttrPathPart) :=
  attrPathPartsFuel defaultDesugarFuel parts

def lambdaParam (param : LambdaParam) : M Core.LambdaParam :=
  lambdaParamFuel defaultDesugarFuel param

def paramEntries (entries : List ParamEntry) : M (List Core.ParamEntry) :=
  paramEntriesFuel defaultDesugarFuel entries

def expr (surface : Expr) : M Core.Expr :=
  exprFuel defaultDesugarFuel surface

def exprs (items : List Expr) : M (List Core.Expr) :=
  exprsFuel defaultDesugarFuel items

def binding (surfaceBinding : Binding) : M (List Core.Binding) :=
  bindingFuel defaultDesugarFuel surfaceBinding

def bindings (surfaceBindings : List Binding) : M (List Core.Binding) :=
  bindingsFuel defaultDesugarFuel surfaceBindings

def exprToCore (surface : Expr) : M Core.Expr :=
  expr surface

end Desugar

def desugar (surface : Expr) : Except String Core.Expr :=
  Desugar.exprToCore surface

end NixParserLean
