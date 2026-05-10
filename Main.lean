import NixParserLean

inductive OutputFormat where
  | repr
  | json
  deriving BEq

structure Options where
  input : String
  filePath? : Option String := none
  desugar : Bool := false
  eval : Bool := false
  evalImports : Bool := false
  coreValidationSmoke : Bool := false
  fuel : Nat := NixParserLean.Core.Eval.defaultFuel
  format : OutputFormat := .repr
  help : Bool := false

def defaultInput : String :=
  "{ answer = 42; values = [ true null \"nix\" ]; }"

def helpText : String :=
  "usage: nixparserlean [--help] [--file PATH] [--desugar] [--eval|--eval-imports] [--fuel N] [--format repr|json]\n" ++
  "\n" ++
  "Options:\n" ++
  "  --file PATH                 Read Nix source from PATH\n" ++
  "  --desugar                   Print validated core AST\n" ++
  "  --eval                      Evaluate validated core AST\n" ++
  "  --eval-imports              Evaluate with host IO for relative path imports\n" ++
  "  --fuel N                    Set evaluator thunk-forcing fuel for --eval\n" ++
  "  --format repr|json          Select output format (default: repr)\n" ++
  "  --core-validation-smoke     Internal e2e smoke mode for core validation\n" ++
  "  --help                      Show this help text"

def readFile (path : String) : IO (Except String String) := do
  try
    pure (.ok (← IO.FS.readFile path))
  catch err =>
    pure (.error s!"could not read {path}: {err}")

def parseFormat (raw : String) : Except String OutputFormat :=
  match raw with
  | "repr" => .ok .repr
  | "json" => .ok .json
  | other => .error s!"unknown output format: {other}"

partial def parseArgs : List String -> Options -> List String -> IO (Except String Options)
  | [], options, inlineParts =>
      let input :=
        if inlineParts.isEmpty then options.input else " ".intercalate inlineParts.reverse
      pure (.ok { options with input })
  | "--help" :: rest, options, inlineParts =>
      parseArgs rest { options with help := true } inlineParts
  | "--desugar" :: rest, options, inlineParts =>
      parseArgs rest { options with desugar := true } inlineParts
  | "--eval" :: rest, options, inlineParts =>
      parseArgs rest { options with eval := true } inlineParts
  | "--eval-imports" :: rest, options, inlineParts =>
      parseArgs rest { options with eval := true, evalImports := true } inlineParts
  | "--core-validation-smoke" :: rest, options, inlineParts =>
      parseArgs rest { options with coreValidationSmoke := true } inlineParts
  | "--file" :: path :: rest, options, inlineParts => do
      match ← readFile path with
      | .ok input => parseArgs rest { options with input, filePath? := some path } inlineParts
      | .error err => pure (.error err)
  | "--file" :: [], _, _ =>
      pure (.error "missing value for --file")
  | "--fuel" :: rawFuel :: rest, options, inlineParts =>
      match rawFuel.toNat? with
      | none => pure (.error s!"invalid fuel value: {rawFuel}")
      | some fuel => parseArgs rest { options with fuel } inlineParts
  | "--fuel" :: [], _, _ =>
      pure (.error "missing value for --fuel")
  | "--format" :: rawFormat :: rest, options, inlineParts =>
      match parseFormat rawFormat with
      | .ok format => parseArgs rest { options with format } inlineParts
      | .error err => pure (.error err)
  | "--format" :: [], _, _ =>
      pure (.error "missing value for --format")
  | arg :: rest, options, inlineParts =>
      if arg.startsWith "--" then
        pure (.error s!"unknown flag: {arg}")
      else
        parseArgs rest options (arg :: inlineParts)

def readInput (args : List String) : IO (Except String Options) :=
  parseArgs args { input := defaultInput } []

def coreValidationSmokeExpr : NixParserLean.Core.Expr :=
  .select .null [] none

def jsonEscapeChar : Char -> String
  | '"' => "\\\""
  | '\\' => "\\\\"
  | '\n' => "\\n"
  | '\r' => "\\r"
  | '\t' => "\\t"
  | c => String.singleton c

def jsonString (text : String) : String :=
  "\"" ++ String.join (text.toList.map jsonEscapeChar) ++ "\""

def jsonArray (items : List String) : String :=
  "[" ++ ",".intercalate items ++ "]"

def jsonField (name value : String) : String :=
  jsonString name ++ ":" ++ value

def jsonObject (fields : List (String × String)) : String :=
  "{" ++ ",".intercalate (fields.map (fun (name, value) => jsonField name value)) ++ "}"

def unaryOpJson : NixParserLean.UnaryOp -> String
  | .not => jsonString "not"
  | .negate => jsonString "negate"

def binaryOpJson : NixParserLean.BinaryOp -> String
  | .equal => jsonString "equal"
  | .notEqual => jsonString "notEqual"
  | .less => jsonString "less"
  | .greater => jsonString "greater"
  | .lessOrEqual => jsonString "lessOrEqual"
  | .greaterOrEqual => jsonString "greaterOrEqual"
  | .and => jsonString "and"
  | .or => jsonString "or"
  | .implies => jsonString "implies"
  | .add => jsonString "add"
  | .subtract => jsonString "subtract"
  | .multiply => jsonString "multiply"
  | .divide => jsonString "divide"
  | .concat => jsonString "concat"
  | .update => jsonString "update"

mutual
partial def surfaceExprJson : NixParserLean.Expr -> String
  | .int value => jsonObject [("kind", jsonString "int"), ("value", toString value)]
  | .float value => jsonObject [("kind", jsonString "float"), ("value", jsonString value)]
  | .str parts => jsonObject [("kind", jsonString "str"), ("parts", jsonArray (parts.map surfaceStringPartJson))]
  | .bool value => jsonObject [("kind", jsonString "bool"), ("value", if value then "true" else "false")]
  | .null => jsonObject [("kind", jsonString "null")]
  | .ident name => jsonObject [("kind", jsonString "ident"), ("name", jsonString name)]
  | .path path => jsonObject [("kind", jsonString "path"), ("path", jsonString path)]
  | .list items => jsonObject [("kind", jsonString "list"), ("items", jsonArray (items.map surfaceExprJson))]
  | .attrset recursive bindings =>
      jsonObject [
        ("kind", jsonString "attrset"),
        ("recursive", if recursive then "true" else "false"),
        ("bindings", jsonArray (bindings.map surfaceBindingJson))
      ]
  | .letIn bindings body =>
      jsonObject [
        ("kind", jsonString "letIn"),
        ("bindings", jsonArray (bindings.map surfaceBindingJson)),
        ("body", surfaceExprJson body)
      ]
  | .lambda param body =>
      jsonObject [("kind", jsonString "lambda"), ("param", surfaceLambdaParamJson param), ("body", surfaceExprJson body)]
  | .ifThenElse condition thenBranch elseBranch =>
      jsonObject [
        ("kind", jsonString "ifThenElse"),
        ("condition", surfaceExprJson condition),
        ("then", surfaceExprJson thenBranch),
        ("else", surfaceExprJson elseBranch)
      ]
  | .assertExpr condition body =>
      jsonObject [("kind", jsonString "assert"), ("condition", surfaceExprJson condition), ("body", surfaceExprJson body)]
  | .withExpr scope body =>
      jsonObject [("kind", jsonString "with"), ("scope", surfaceExprJson scope), ("body", surfaceExprJson body)]
  | .select base path default? =>
      jsonObject [
        ("kind", jsonString "select"),
        ("base", surfaceExprJson base),
        ("path", surfaceAttrPathJson path),
        ("default", match default? with | none => "null" | some expr => surfaceExprJson expr)
      ]
  | .hasAttr base path =>
      jsonObject [("kind", jsonString "hasAttr"), ("base", surfaceExprJson base), ("path", surfaceAttrPathJson path)]
  | .app function argument =>
      jsonObject [("kind", jsonString "app"), ("function", surfaceExprJson function), ("argument", surfaceExprJson argument)]
  | .unary op expr =>
      jsonObject [("kind", jsonString "unary"), ("op", unaryOpJson op), ("expr", surfaceExprJson expr)]
  | .binary op left right =>
      jsonObject [("kind", jsonString "binary"), ("op", binaryOpJson op), ("left", surfaceExprJson left), ("right", surfaceExprJson right)]

partial def surfaceStringPartJson : NixParserLean.StringPart -> String
  | .text text => jsonObject [("kind", jsonString "text"), ("text", jsonString text)]
  | .interpolation expr => jsonObject [("kind", jsonString "interpolation"), ("expr", surfaceExprJson expr)]

partial def surfaceAttrPathJson (path : NixParserLean.AttrPath) : String :=
  jsonArray (path.parts.map surfaceAttrPathPartJson)

partial def surfaceAttrPathPartJson : NixParserLean.AttrPathPart -> String
  | .static name => jsonObject [("kind", jsonString "static"), ("name", jsonString name)]
  | .dynamicString parts => jsonObject [("kind", jsonString "dynamicString"), ("parts", jsonArray (parts.map surfaceStringPartJson))]

partial def surfaceBindingJson : NixParserLean.Binding -> String
  | .assign path value =>
      jsonObject [("kind", jsonString "assign"), ("path", surfaceAttrPathJson path), ("value", surfaceExprJson value)]
  | .inherit names =>
      jsonObject [("kind", jsonString "inherit"), ("names", jsonArray (names.map jsonString))]
  | .inheritFrom scope names =>
      jsonObject [("kind", jsonString "inheritFrom"), ("scope", surfaceExprJson scope), ("names", jsonArray (names.map jsonString))]

partial def surfaceLambdaParamJson : NixParserLean.LambdaParam -> String
  | .ident name => jsonObject [("kind", jsonString "ident"), ("name", jsonString name)]
  | .attrset paramSet => jsonObject [("kind", jsonString "attrset"), ("paramSet", surfaceParamSetJson paramSet)]
  | .alias name param => jsonObject [("kind", jsonString "alias"), ("name", jsonString name), ("param", surfaceLambdaParamJson param)]

partial def surfaceParamSetJson (paramSet : NixParserLean.ParamSet) : String :=
  jsonObject [
    ("ellipsis", if paramSet.ellipsis then "true" else "false"),
    ("entries", jsonArray (paramSet.entries.map surfaceParamEntryJson))
  ]

partial def surfaceParamEntryJson (entry : NixParserLean.ParamEntry) : String :=
  jsonObject [
    ("name", jsonString entry.name),
    ("default", match entry.default? with | none => "null" | some expr => surfaceExprJson expr)
  ]
end

mutual
partial def coreExprJson : NixParserLean.Core.Expr -> String
  | .int value => jsonObject [("kind", jsonString "int"), ("value", toString value)]
  | .float value => jsonObject [("kind", jsonString "float"), ("value", jsonString value)]
  | .str parts => jsonObject [("kind", jsonString "str"), ("parts", jsonArray (parts.map coreStringPartJson))]
  | .bool value => jsonObject [("kind", jsonString "bool"), ("value", if value then "true" else "false")]
  | .null => jsonObject [("kind", jsonString "null")]
  | .ident name => jsonObject [("kind", jsonString "ident"), ("name", jsonString name)]
  | .path path => jsonObject [("kind", jsonString "path"), ("path", jsonString path)]
  | .list items => jsonObject [("kind", jsonString "list"), ("items", jsonArray (items.map coreExprJson))]
  | .attrset recursive bindings =>
      jsonObject [
        ("kind", jsonString "attrset"),
        ("recursive", if recursive then "true" else "false"),
        ("bindings", jsonArray (bindings.map coreBindingJson))
      ]
  | .letIn bindings body =>
      jsonObject [
        ("kind", jsonString "letIn"),
        ("bindings", jsonArray (bindings.map coreBindingJson)),
        ("body", coreExprJson body)
      ]
  | .lambda param body => jsonObject [("kind", jsonString "lambda"), ("param", coreLambdaParamJson param), ("body", coreExprJson body)]
  | .ifThenElse condition thenBranch elseBranch =>
      jsonObject [("kind", jsonString "ifThenElse"), ("condition", coreExprJson condition), ("then", coreExprJson thenBranch), ("else", coreExprJson elseBranch)]
  | .assertExpr condition body => jsonObject [("kind", jsonString "assert"), ("condition", coreExprJson condition), ("body", coreExprJson body)]
  | .withExpr scope body => jsonObject [("kind", jsonString "with"), ("scope", coreExprJson scope), ("body", coreExprJson body)]
  | .select base path default? =>
      jsonObject [
        ("kind", jsonString "select"),
        ("base", coreExprJson base),
        ("path", jsonArray (path.map coreAttrPathPartJson)),
        ("default", match default? with | none => "null" | some expr => coreExprJson expr)
      ]
  | .hasAttr base path => jsonObject [("kind", jsonString "hasAttr"), ("base", coreExprJson base), ("path", jsonArray (path.map coreAttrPathPartJson))]
  | .app function argument => jsonObject [("kind", jsonString "app"), ("function", coreExprJson function), ("argument", coreExprJson argument)]
  | .unary op expr => jsonObject [("kind", jsonString "unary"), ("op", unaryOpJson op), ("expr", coreExprJson expr)]
  | .binary op left right => jsonObject [("kind", jsonString "binary"), ("op", binaryOpJson op), ("left", coreExprJson left), ("right", coreExprJson right)]

partial def coreStringPartJson : NixParserLean.Core.StringPart -> String
  | .text text => jsonObject [("kind", jsonString "text"), ("text", jsonString text)]
  | .interpolation expr => jsonObject [("kind", jsonString "interpolation"), ("expr", coreExprJson expr)]

partial def coreAttrPathPartJson : NixParserLean.Core.AttrPathPart -> String
  | .static name => jsonObject [("kind", jsonString "static"), ("name", jsonString name)]
  | .dynamicString parts => jsonObject [("kind", jsonString "dynamicString"), ("parts", jsonArray (parts.map coreStringPartJson))]

partial def coreBindingJson : NixParserLean.Core.Binding -> String
  | .staticAssign name value => jsonObject [("kind", jsonString "staticAssign"), ("name", jsonString name), ("value", coreExprJson value)]
  | .inheritAssign name => jsonObject [("kind", jsonString "inheritAssign"), ("name", jsonString name)]
  | .dynamicAssign path value => jsonObject [("kind", jsonString "dynamicAssign"), ("path", jsonArray (path.map coreAttrPathPartJson)), ("value", coreExprJson value)]

partial def coreLambdaParamJson : NixParserLean.Core.LambdaParam -> String
  | .ident name => jsonObject [("kind", jsonString "ident"), ("name", jsonString name)]
  | .attrset paramSet => jsonObject [("kind", jsonString "attrset"), ("paramSet", coreParamSetJson paramSet)]
  | .alias name param => jsonObject [("kind", jsonString "alias"), ("name", jsonString name), ("param", coreLambdaParamJson param)]

partial def coreParamSetJson (paramSet : NixParserLean.Core.ParamSet) : String :=
  jsonObject [("ellipsis", if paramSet.ellipsis then "true" else "false"), ("entries", jsonArray (paramSet.entries.map coreParamEntryJson))]

partial def coreParamEntryJson (entry : NixParserLean.Core.ParamEntry) : String :=
  jsonObject [("name", jsonString entry.name), ("default", match entry.default? with | none => "null" | some expr => coreExprJson expr)]
end

partial def evalValueJson : NixParserLean.Core.Eval.Value -> String
  | .int value => jsonObject [("kind", jsonString "int"), ("value", toString value)]
  | .float value => jsonObject [("kind", jsonString "float"), ("value", jsonString value)]
  | .str value => jsonObject [("kind", jsonString "str"), ("value", jsonString value)]
  | .bool value => jsonObject [("kind", jsonString "bool"), ("value", if value then "true" else "false")]
  | .null => jsonObject [("kind", jsonString "null")]
  | .list items => jsonObject [("kind", jsonString "list"), ("items", jsonArray (items.map evalValueJson))]
  | .attrset attrs =>
      let attrJson : String × NixParserLean.Core.Eval.Value -> String
        | (name, value) => jsonObject [("name", jsonString name), ("value", evalValueJson value)]
      jsonObject [("kind", jsonString "attrset"), ("attrs", jsonArray (attrs.map attrJson))]
  | .closure _ _ _ => jsonObject [("kind", jsonString "closure")]

def sourceBaseDir (options : Options) : String :=
  match options.filePath? with
  | none => "."
  | some path => NixParserLean.HostEval.dirname path

def prepareCoreForEval (options : Options) (coreExpr : NixParserLean.Core.Expr) :
    IO (Except String NixParserLean.Core.Expr) := do
  if options.eval && options.evalImports then
    NixParserLean.HostEval.resolveImports options.fuel (sourceBaseDir options) coreExpr
  else
    pure (.ok coreExpr)

def printCoreResult (options : Options) (coreExpr : NixParserLean.Core.Expr) : IO UInt32 := do
  match ← prepareCoreForEval options coreExpr with
  | .error err =>
      IO.eprintln err
      pure 1
  | .ok coreExpr =>
      match NixParserLean.Core.validate coreExpr with
      | .ok () =>
          if options.eval then
            match NixParserLean.Core.evalWithFuel options.fuel coreExpr with
            | .ok value =>
                match options.format with
                | .repr => IO.println (repr value)
                | .json => IO.println (evalValueJson value)
                pure 0
            | .error err =>
                IO.eprintln err
                pure 1
          else
            match options.format with
            | .repr => IO.println (repr coreExpr)
            | .json => IO.println (coreExprJson coreExpr)
            pure 0
      | .error err =>
          IO.eprintln err
          pure 1

def printResult (options : Options) (expr : NixParserLean.Expr) : IO UInt32 := do
  match NixParserLean.validate expr with
  | .ok () =>
      if options.desugar || options.eval then
        match NixParserLean.desugar expr with
        | .ok coreExpr => printCoreResult options coreExpr
        | .error err =>
            IO.eprintln err
            pure 1
      else
        match options.format with
        | .repr => IO.println (repr expr)
        | .json => IO.println (surfaceExprJson expr)
        pure 0
  | .error err =>
      IO.eprintln err
      pure 1

def main (args : List String) : IO UInt32 := do
  match ← readInput args with
  | .error err =>
      IO.eprintln err
      pure 1
  | .ok options =>
      if options.help then
        IO.println helpText
        pure 0
      else if options.coreValidationSmoke then
        printCoreResult options coreValidationSmokeExpr
      else
        match NixParserLean.parse options.input with
        | .ok expr => printResult options expr
        | .error err =>
            IO.eprintln err
            pure 1
