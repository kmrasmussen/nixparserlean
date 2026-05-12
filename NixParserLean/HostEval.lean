import NixParserLean.CoreEval
import NixParserLean.CoreValidate
import NixParserLean.Desugar
import NixParserLean.Parser
import NixParserLean.Validate

namespace NixParserLean
namespace HostEval

abbrev M := Except String
abbrev SearchPathMap := List (String × String)

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

def normalizePathParts (absolute : Bool) : List String -> List String -> List String
  | acc, [] => acc.reverse
  | acc, part :: parts =>
      if part == "" || part == "." then
        normalizePathParts absolute acc parts
      else if part == ".." then
        match acc with
        | [] =>
            if absolute then
              normalizePathParts absolute [] parts
            else
              normalizePathParts absolute (".." :: acc) parts
        | ".." :: _ =>
            if absolute then
              normalizePathParts absolute acc parts
            else
              normalizePathParts absolute (".." :: acc) parts
        | _ :: rest => normalizePathParts absolute rest parts
      else
        normalizePathParts absolute (part :: acc) parts

def normalizeHostImportPath (path : String) : String :=
  let absolute := path.startsWith "/"
  let parts := normalizePathParts absolute [] (path.splitOn "/")
  if absolute then
    match parts with
    | [] => "/"
    | _ => "/" ++ "/".intercalate parts
  else
    match parts with
    | [] => "."
    | _ => "/".intercalate parts

def anglePathInner? (path : String) : Option String :=
  match path.toList with
  | '<' :: rest =>
      match rest.reverse with
      | '>' :: innerReversed => some (String.ofList innerReversed.reverse)
      | _ => none
  | _ => none

def findSearchPathRoot? (name : String) : SearchPathMap -> Option String
  | [] => none
  | (candidate, root) :: rest =>
      if candidate == name then some root else findSearchPathRoot? name rest

def resolveAngleImportPath (searchPaths : SearchPathMap) (path : String) : M String := do
  let inner ←
    match anglePathInner? path with
    | some inner => pure inner
    | none => throw s!"eval error: unsupported import path '{path}'"
  match inner.splitOn "/" with
  | [] => throw s!"eval error: unsupported import path '{path}'"
  | name :: rest =>
      if name == "" then
        throw s!"eval error: unsupported import path '{path}'"
      else
        match findSearchPathRoot? name searchPaths with
        | none => throw s!"eval error: search path '{name}' is not configured"
        | some root =>
            let suffix := "/".intercalate rest
            if suffix == "" then
              pure (normalizeHostImportPath root)
            else
              pure (normalizeHostImportPath (joinPath root suffix))

def isSupportedImportPath (path : String) : Bool :=
  path.startsWith "./" || path.startsWith "../"

def resolveImportPath (searchPaths : SearchPathMap) (baseDir path : String) : M String :=
  if isSupportedImportPath path then
    pure (normalizeHostImportPath (joinPath baseDir path))
  else
    match anglePathInner? path with
    | some _ => resolveAngleImportPath searchPaths path
    | none => throw s!"eval error: unsupported import path '{path}'"

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
partial def resolveExprImports (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String) :
    Core.Expr -> IO (M Core.Expr)
  | .int value => pure (.ok (.int value))
  | .float value => pure (.ok (.float value))
  | .str parts => do
      match ← resolveStringParts searchPaths fuel baseDir stack parts with
      | .ok parts => pure (.ok (.str parts))
      | .error err => pure (.error err)
  | .bool value => pure (.ok (.bool value))
  | .null => pure (.ok .null)
  | .ident name => pure (.ok (.ident name))
  | .path path => pure (.ok (.path path))
  | .list items => do
      match ← resolveExprList searchPaths fuel baseDir stack items with
      | .ok items => pure (.ok (.list items))
      | .error err => pure (.error err)
  | .attrset recursive bindings => do
      match ← resolveBindings searchPaths fuel baseDir stack bindings with
      | .ok bindings => pure (.ok (.attrset recursive bindings))
      | .error err => pure (.error err)
  | .letIn bindings body => do
      match ← resolveBindings searchPaths fuel baseDir stack bindings with
      | .error err => pure (.error err)
      | .ok bindings =>
          match ← resolveExprImports searchPaths fuel baseDir stack body with
          | .ok body => pure (.ok (.letIn bindings body))
          | .error err => pure (.error err)
  | .lambda param body => do
      match ← resolveLambdaParam searchPaths fuel baseDir stack param with
      | .error err => pure (.error err)
      | .ok param =>
          match ← resolveExprImports searchPaths fuel baseDir stack body with
          | .ok body => pure (.ok (.lambda param body))
          | .error err => pure (.error err)
  | .ifThenElse condition thenBranch elseBranch => do
      match ← resolveExprImports searchPaths fuel baseDir stack condition with
      | .error err => pure (.error err)
      | .ok condition =>
          match ← resolveExprImports searchPaths fuel baseDir stack thenBranch with
          | .error err => pure (.error err)
          | .ok thenBranch =>
              match ← resolveExprImports searchPaths fuel baseDir stack elseBranch with
              | .ok elseBranch => pure (.ok (.ifThenElse condition thenBranch elseBranch))
              | .error err => pure (.error err)
  | .assertExpr condition body => do
      match ← resolveExprImports searchPaths fuel baseDir stack condition with
      | .error err => pure (.error err)
      | .ok condition =>
          match ← resolveExprImports searchPaths fuel baseDir stack body with
          | .ok body => pure (.ok (.assertExpr condition body))
          | .error err => pure (.error err)
  | .withExpr scope body => do
      match ← resolveExprImports searchPaths fuel baseDir stack scope with
      | .error err => pure (.error err)
      | .ok scope =>
          match ← resolveExprImports searchPaths fuel baseDir stack body with
          | .ok body => pure (.ok (.withExpr scope body))
          | .error err => pure (.error err)
  | .select base path default? => do
      match ← resolveExprImports searchPaths fuel baseDir stack base with
      | .error err => pure (.error err)
      | .ok base =>
          match ← resolveAttrPath searchPaths fuel baseDir stack path with
          | .error err => pure (.error err)
          | .ok path =>
              match default? with
              | none => pure (.ok (.select base path none))
              | some defaultExpr =>
                  match ← resolveExprImports searchPaths fuel baseDir stack defaultExpr with
                  | .ok defaultExpr => pure (.ok (.select base path (some defaultExpr)))
                  | .error err => pure (.error err)
  | .hasAttr base path => do
      match ← resolveExprImports searchPaths fuel baseDir stack base with
      | .error err => pure (.error err)
      | .ok base =>
          match ← resolveAttrPath searchPaths fuel baseDir stack path with
          | .ok path => pure (.ok (.hasAttr base path))
          | .error err => pure (.error err)
  | .app (.app (.ident "import") (.path path)) argument => do
      match ← loadImportAsValue searchPaths fuel baseDir stack path with
      | .error err => pure (.error err)
      | .ok (.closure closureEnv param body) =>
          match ← resolveExprImports searchPaths fuel baseDir stack argument with
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
              match ← resolveExprImports searchPaths fuel baseDir stack argument with
              | .ok argument => pure (.ok (.app function argument))
              | .error err => pure (.error err)
  | .app (.ident "import") (.path path) =>
      loadImportAsExpr searchPaths fuel baseDir stack path
  | .app (.ident "import") _ =>
      pure (.error "eval error: import argument must be a path literal")
  | .app function argument => do
      match ← resolveExprImports searchPaths fuel baseDir stack function with
      | .error err => pure (.error err)
      | .ok function =>
          match ← resolveExprImports searchPaths fuel baseDir stack argument with
          | .ok argument => pure (.ok (.app function argument))
          | .error err => pure (.error err)
  | .unary op inner => do
      match ← resolveExprImports searchPaths fuel baseDir stack inner with
      | .ok inner => pure (.ok (.unary op inner))
      | .error err => pure (.error err)
  | .binary op left right => do
      match ← resolveExprImports searchPaths fuel baseDir stack left with
      | .error err => pure (.error err)
      | .ok left =>
          match ← resolveExprImports searchPaths fuel baseDir stack right with
          | .ok right => pure (.ok (.binary op left right))
          | .error err => pure (.error err)

partial def resolveStringParts (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String) :
    List Core.StringPart -> IO (M (List Core.StringPart))
  | [] => pure (.ok [])
  | .text text :: parts => do
      match ← resolveStringParts searchPaths fuel baseDir stack parts with
      | .ok parts => pure (.ok (.text text :: parts))
      | .error err => pure (.error err)
  | .interpolation expr :: parts => do
      match ← resolveExprImports searchPaths fuel baseDir stack expr with
      | .error err => pure (.error err)
      | .ok expr =>
          match ← resolveStringParts searchPaths fuel baseDir stack parts with
          | .ok parts => pure (.ok (.interpolation expr :: parts))
          | .error err => pure (.error err)

partial def resolveExprList (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String) :
    List Core.Expr -> IO (M (List Core.Expr))
  | [] => pure (.ok [])
  | expr :: exprs => do
      match ← resolveExprImports searchPaths fuel baseDir stack expr with
      | .error err => pure (.error err)
      | .ok expr =>
          match ← resolveExprList searchPaths fuel baseDir stack exprs with
          | .ok exprs => pure (.ok (expr :: exprs))
          | .error err => pure (.error err)

partial def resolveBinding (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String) :
    Core.Binding -> IO (M Core.Binding)
  | .staticAssign name value => do
      match ← resolveExprImports searchPaths fuel baseDir stack value with
      | .ok value => pure (.ok (.staticAssign name value))
      | .error err => pure (.error err)
  | .inheritAssign name => pure (.ok (.inheritAssign name))
  | .dynamicAssign path value => do
      match ← resolveAttrPath searchPaths fuel baseDir stack path with
      | .error err => pure (.error err)
      | .ok path =>
          match ← resolveExprImports searchPaths fuel baseDir stack value with
          | .ok value => pure (.ok (.dynamicAssign path value))
          | .error err => pure (.error err)

partial def resolveBindings (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String) :
    List Core.Binding -> IO (M (List Core.Binding))
  | [] => pure (.ok [])
  | binding :: bindings => do
      match ← resolveBinding searchPaths fuel baseDir stack binding with
      | .error err => pure (.error err)
      | .ok binding =>
          match ← resolveBindings searchPaths fuel baseDir stack bindings with
          | .ok bindings => pure (.ok (binding :: bindings))
          | .error err => pure (.error err)

partial def resolveLambdaParam (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String) :
    Core.LambdaParam -> IO (M Core.LambdaParam)
  | .ident name => pure (.ok (.ident name))
  | .attrset paramSet => do
      match ← resolveParamEntries searchPaths fuel baseDir stack paramSet.entries with
      | .ok entries => pure (.ok (.attrset { paramSet with entries }))
      | .error err => pure (.error err)
  | .alias name param => do
      match ← resolveLambdaParam searchPaths fuel baseDir stack param with
      | .ok param => pure (.ok (.alias name param))
      | .error err => pure (.error err)

partial def resolveParamEntries (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String) :
    List Core.ParamEntry -> IO (M (List Core.ParamEntry))
  | [] => pure (.ok [])
  | entry :: entries => do
      let default?Result : M (Option Core.Expr) ←
        match entry.default? with
        | none => pure (Except.ok none)
        | some defaultExpr => do
            match ← resolveExprImports searchPaths fuel baseDir stack defaultExpr with
            | .ok defaultExpr => pure (Except.ok (some defaultExpr))
            | .error err => pure (Except.error err)
      match default?Result with
      | .error err => pure (.error err)
      | .ok default? =>
          match ← resolveParamEntries searchPaths fuel baseDir stack entries with
          | .ok entries => pure (.ok ({ entry with default? } :: entries))
          | .error err => pure (.error err)

partial def resolveAttrPath (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String) :
    List Core.AttrPathPart -> IO (M (List Core.AttrPathPart))
  | [] => pure (.ok [])
  | part :: parts => do
      match part with
      | .static name =>
          match ← resolveAttrPath searchPaths fuel baseDir stack parts with
          | .ok parts => pure (.ok (.static name :: parts))
          | .error err => pure (.error err)
      | .dynamicString stringParts =>
          match ← resolveStringParts searchPaths fuel baseDir stack stringParts with
          | .error err => pure (.error err)
          | .ok stringParts =>
              match ← resolveAttrPath searchPaths fuel baseDir stack parts with
              | .ok parts => pure (.ok (.dynamicString stringParts :: parts))
              | .error err => pure (.error err)

partial def loadImportAsValue (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String)
    (rawPath : String) : IO (M Core.Eval.Value) := do
  match fuel with
  | 0 => pure (.error "eval error: import depth exhausted")
  | fuel + 1 =>
      match resolveImportPath searchPaths baseDir rawPath with
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
                    match ← resolveExprImports searchPaths fuel importedBaseDir (path :: stack) core with
                    | .error err => pure (.error err)
                    | .ok core =>
                        pure (Core.evalWithFuel fuel core)

partial def loadImportAsExpr (searchPaths : SearchPathMap) (fuel : Nat)
    (baseDir : String) (stack : List String)
    (rawPath : String) : IO (M Core.Expr) := do
  match ← loadImportAsValue searchPaths fuel baseDir stack rawPath with
  | .error err => pure (.error err)
  | .ok value => pure (valueToExpr value)
end

def resolveImports (searchPaths : SearchPathMap) (fuel : Nat) (baseDir : String) (expr : Core.Expr) :
    IO (M Core.Expr) :=
  resolveExprImports searchPaths fuel baseDir [] expr

end HostEval
end NixParserLean
