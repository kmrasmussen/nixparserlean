import NixParserLean.CoreEval
import NixParserLean.CoreValidate
import NixParserLean.Desugar
import NixParserLean.Parser
import NixParserLean.Validate

namespace NixParserLean
namespace HostEval

abbrev M := Except String

def dropLast : List α -> List α
  | [] => []
  | [_] => []
  | item :: items => item :: dropLast items

def dirname (path : String) : String :=
  let parts := path.splitOn "/"
  match parts with
  | [] => "."
  | [_] => "."
  | _ =>
      let dir := "/".intercalate (dropLast parts)
      if dir == "" then
        if path.startsWith "/" then "/" else "."
      else
        dir

def joinPath (base path : String) : String :=
  if base == "" || base == "." then
    path
  else if base.endsWith "/" then
    base ++ path
  else
    base ++ "/" ++ path

def isSupportedImportPath (path : String) : Bool :=
  path.startsWith "./" || path.startsWith "../"

def resolveImportPath (baseDir path : String) : M String :=
  if isSupportedImportPath path then
    pure (joinPath baseDir path)
  else
    throw s!"eval error: unsupported import path '{path}'"

def readImportFile (path : String) : IO (M String) := do
  try
    pure (.ok (← IO.FS.readFile path))
  catch err =>
    pure (.error s!"eval error: could not import {path}: {err}")

def coreFromSource (source : String) : M Core.Expr := do
  let surface ←
    match parse source with
    | .ok surface => pure surface
    | .error err => throw (toString err)
  validate surface
  let core ← desugar surface
  Core.validate core
  pure core

mutual
partial def valueToExpr : Core.Eval.Value -> M Core.Expr
  | .int value => pure (.int value)
  | .float value => pure (.float value)
  | .str value => pure (.str [.text value])
  | .bool value => pure (.bool value)
  | .null => pure .null
  | .path path => pure (.path path)
  | .list items => do
      pure (.list (← valuesToExprs items))
  | .attrset attrs => do
      pure (.attrset false (← attrsToBindings attrs))
  | .closure _ _ _ => throw "eval error: unsupported imported function values"

partial def valuesToExprs : List Core.Eval.Value -> M (List Core.Expr)
  | [] => pure []
  | value :: values => do
      let value ← valueToExpr value
      let values ← valuesToExprs values
      pure (value :: values)

partial def attrsToBindings : List (String × Core.Eval.Value) -> M (List Core.Binding)
  | [] => pure []
  | (name, value) :: attrs => do
      let value ← valueToExpr value
      let attrs ← attrsToBindings attrs
      pure (.staticAssign name value :: attrs)
end

partial def containsPath (path : String) : List String -> Bool
  | [] => false
  | candidate :: paths => candidate == path || containsPath path paths

mutual
partial def resolveExprImports (fuel : Nat) (baseDir : String) (stack : List String) :
    Core.Expr -> IO (M Core.Expr)
  | .int value => pure (.ok (.int value))
  | .float value => pure (.ok (.float value))
  | .str parts => do
      match ← resolveStringParts fuel baseDir stack parts with
      | .ok parts => pure (.ok (.str parts))
      | .error err => pure (.error err)
  | .bool value => pure (.ok (.bool value))
  | .null => pure (.ok .null)
  | .ident name => pure (.ok (.ident name))
  | .path path => pure (.ok (.path path))
  | .list items => do
      match ← resolveExprList fuel baseDir stack items with
      | .ok items => pure (.ok (.list items))
      | .error err => pure (.error err)
  | .attrset recursive bindings => do
      match ← resolveBindings fuel baseDir stack bindings with
      | .ok bindings => pure (.ok (.attrset recursive bindings))
      | .error err => pure (.error err)
  | .letIn bindings body => do
      match ← resolveBindings fuel baseDir stack bindings with
      | .error err => pure (.error err)
      | .ok bindings =>
          match ← resolveExprImports fuel baseDir stack body with
          | .ok body => pure (.ok (.letIn bindings body))
          | .error err => pure (.error err)
  | .lambda param body => do
      match ← resolveLambdaParam fuel baseDir stack param with
      | .error err => pure (.error err)
      | .ok param =>
          match ← resolveExprImports fuel baseDir stack body with
          | .ok body => pure (.ok (.lambda param body))
          | .error err => pure (.error err)
  | .ifThenElse condition thenBranch elseBranch => do
      match ← resolveExprImports fuel baseDir stack condition with
      | .error err => pure (.error err)
      | .ok condition =>
          match ← resolveExprImports fuel baseDir stack thenBranch with
          | .error err => pure (.error err)
          | .ok thenBranch =>
              match ← resolveExprImports fuel baseDir stack elseBranch with
              | .ok elseBranch => pure (.ok (.ifThenElse condition thenBranch elseBranch))
              | .error err => pure (.error err)
  | .assertExpr condition body => do
      match ← resolveExprImports fuel baseDir stack condition with
      | .error err => pure (.error err)
      | .ok condition =>
          match ← resolveExprImports fuel baseDir stack body with
          | .ok body => pure (.ok (.assertExpr condition body))
          | .error err => pure (.error err)
  | .withExpr scope body => do
      match ← resolveExprImports fuel baseDir stack scope with
      | .error err => pure (.error err)
      | .ok scope =>
          match ← resolveExprImports fuel baseDir stack body with
          | .ok body => pure (.ok (.withExpr scope body))
          | .error err => pure (.error err)
  | .select base path default? => do
      match ← resolveExprImports fuel baseDir stack base with
      | .error err => pure (.error err)
      | .ok base =>
          match ← resolveAttrPath fuel baseDir stack path with
          | .error err => pure (.error err)
          | .ok path =>
              match default? with
              | none => pure (.ok (.select base path none))
              | some defaultExpr =>
                  match ← resolveExprImports fuel baseDir stack defaultExpr with
                  | .ok defaultExpr => pure (.ok (.select base path (some defaultExpr)))
                  | .error err => pure (.error err)
  | .hasAttr base path => do
      match ← resolveExprImports fuel baseDir stack base with
      | .error err => pure (.error err)
      | .ok base =>
          match ← resolveAttrPath fuel baseDir stack path with
          | .ok path => pure (.ok (.hasAttr base path))
          | .error err => pure (.error err)
  | .app (.app (.ident "import") (.path path)) argument => do
      match ← loadImportAsValue fuel baseDir stack path with
      | .error err => pure (.error err)
      | .ok (.closure closureEnv param body) =>
          match ← resolveExprImports fuel baseDir stack argument with
          | .error err => pure (.error err)
          | .ok argument =>
              match Core.evalWithFuel fuel argument with
              | .error err => pure (.error err)
              | .ok argumentValue =>
                  match Core.Eval.bindParam fuel [] param argumentValue closureEnv with
                  | .error err => pure (.error err)
                  | .ok env =>
                      match Core.Eval.eval fuel [] env body with
                      | .error err => pure (.error err)
                      | .ok value => pure (valueToExpr value)
      | .ok imported =>
          match valueToExpr imported with
          | .error err => pure (.error err)
          | .ok function =>
              match ← resolveExprImports fuel baseDir stack argument with
              | .ok argument => pure (.ok (.app function argument))
              | .error err => pure (.error err)
  | .app (.ident "import") (.path path) =>
      loadImportAsExpr fuel baseDir stack path
  | .app (.ident "import") _ =>
      pure (.error "eval error: import argument must be a path literal")
  | .app function argument => do
      match ← resolveExprImports fuel baseDir stack function with
      | .error err => pure (.error err)
      | .ok function =>
          match ← resolveExprImports fuel baseDir stack argument with
          | .ok argument => pure (.ok (.app function argument))
          | .error err => pure (.error err)
  | .unary op inner => do
      match ← resolveExprImports fuel baseDir stack inner with
      | .ok inner => pure (.ok (.unary op inner))
      | .error err => pure (.error err)
  | .binary op left right => do
      match ← resolveExprImports fuel baseDir stack left with
      | .error err => pure (.error err)
      | .ok left =>
          match ← resolveExprImports fuel baseDir stack right with
          | .ok right => pure (.ok (.binary op left right))
          | .error err => pure (.error err)

partial def resolveStringParts (fuel : Nat) (baseDir : String) (stack : List String) :
    List Core.StringPart -> IO (M (List Core.StringPart))
  | [] => pure (.ok [])
  | .text text :: parts => do
      match ← resolveStringParts fuel baseDir stack parts with
      | .ok parts => pure (.ok (.text text :: parts))
      | .error err => pure (.error err)
  | .interpolation expr :: parts => do
      match ← resolveExprImports fuel baseDir stack expr with
      | .error err => pure (.error err)
      | .ok expr =>
          match ← resolveStringParts fuel baseDir stack parts with
          | .ok parts => pure (.ok (.interpolation expr :: parts))
          | .error err => pure (.error err)

partial def resolveExprList (fuel : Nat) (baseDir : String) (stack : List String) :
    List Core.Expr -> IO (M (List Core.Expr))
  | [] => pure (.ok [])
  | expr :: exprs => do
      match ← resolveExprImports fuel baseDir stack expr with
      | .error err => pure (.error err)
      | .ok expr =>
          match ← resolveExprList fuel baseDir stack exprs with
          | .ok exprs => pure (.ok (expr :: exprs))
          | .error err => pure (.error err)

partial def resolveBinding (fuel : Nat) (baseDir : String) (stack : List String) :
    Core.Binding -> IO (M Core.Binding)
  | .staticAssign name value => do
      match ← resolveExprImports fuel baseDir stack value with
      | .ok value => pure (.ok (.staticAssign name value))
      | .error err => pure (.error err)
  | .inheritAssign name => pure (.ok (.inheritAssign name))
  | .dynamicAssign path value => do
      match ← resolveAttrPath fuel baseDir stack path with
      | .error err => pure (.error err)
      | .ok path =>
          match ← resolveExprImports fuel baseDir stack value with
          | .ok value => pure (.ok (.dynamicAssign path value))
          | .error err => pure (.error err)

partial def resolveBindings (fuel : Nat) (baseDir : String) (stack : List String) :
    List Core.Binding -> IO (M (List Core.Binding))
  | [] => pure (.ok [])
  | binding :: bindings => do
      match ← resolveBinding fuel baseDir stack binding with
      | .error err => pure (.error err)
      | .ok binding =>
          match ← resolveBindings fuel baseDir stack bindings with
          | .ok bindings => pure (.ok (binding :: bindings))
          | .error err => pure (.error err)

partial def resolveLambdaParam (fuel : Nat) (baseDir : String) (stack : List String) :
    Core.LambdaParam -> IO (M Core.LambdaParam)
  | .ident name => pure (.ok (.ident name))
  | .attrset paramSet => do
      match ← resolveParamEntries fuel baseDir stack paramSet.entries with
      | .ok entries => pure (.ok (.attrset { paramSet with entries }))
      | .error err => pure (.error err)
  | .alias name param => do
      match ← resolveLambdaParam fuel baseDir stack param with
      | .ok param => pure (.ok (.alias name param))
      | .error err => pure (.error err)

partial def resolveParamEntries (fuel : Nat) (baseDir : String) (stack : List String) :
    List Core.ParamEntry -> IO (M (List Core.ParamEntry))
  | [] => pure (.ok [])
  | entry :: entries => do
      let default?Result : M (Option Core.Expr) ←
        match entry.default? with
        | none => pure (Except.ok none)
        | some defaultExpr => do
            match ← resolveExprImports fuel baseDir stack defaultExpr with
            | .ok defaultExpr => pure (Except.ok (some defaultExpr))
            | .error err => pure (Except.error err)
      match default?Result with
      | .error err => pure (.error err)
      | .ok default? =>
          match ← resolveParamEntries fuel baseDir stack entries with
          | .ok entries => pure (.ok ({ entry with default? } :: entries))
          | .error err => pure (.error err)

partial def resolveAttrPath (fuel : Nat) (baseDir : String) (stack : List String) :
    List Core.AttrPathPart -> IO (M (List Core.AttrPathPart))
  | [] => pure (.ok [])
  | part :: parts => do
      match part with
      | .static name =>
          match ← resolveAttrPath fuel baseDir stack parts with
          | .ok parts => pure (.ok (.static name :: parts))
          | .error err => pure (.error err)
      | .dynamicString stringParts =>
          match ← resolveStringParts fuel baseDir stack stringParts with
          | .error err => pure (.error err)
          | .ok stringParts =>
              match ← resolveAttrPath fuel baseDir stack parts with
              | .ok parts => pure (.ok (.dynamicString stringParts :: parts))
              | .error err => pure (.error err)

partial def loadImportAsValue (fuel : Nat) (baseDir : String) (stack : List String)
    (rawPath : String) : IO (M Core.Eval.Value) := do
  match fuel with
  | 0 => pure (.error "eval error: import depth exhausted")
  | fuel + 1 =>
      match resolveImportPath baseDir rawPath with
      | .error err => pure (.error err)
      | .ok path =>
          if containsPath path stack then
            pure (.error s!"eval error: recursive import '{path}'")
          else
            match ← readImportFile path with
            | .error err => pure (.error err)
            | .ok source =>
                match coreFromSource source with
                | .error err => pure (.error err)
                | .ok core =>
                    let importedBaseDir := dirname path
                    match ← resolveExprImports fuel importedBaseDir (path :: stack) core with
                    | .error err => pure (.error err)
                    | .ok core =>
                        pure (Core.evalWithFuel fuel core)

partial def loadImportAsExpr (fuel : Nat) (baseDir : String) (stack : List String)
    (rawPath : String) : IO (M Core.Expr) := do
  match ← loadImportAsValue fuel baseDir stack rawPath with
  | .error err => pure (.error err)
  | .ok value => pure (valueToExpr value)
end

def resolveImports (fuel : Nat) (baseDir : String) (expr : Core.Expr) :
    IO (M Core.Expr) :=
  resolveExprImports fuel baseDir [] expr

end HostEval
end NixParserLean
