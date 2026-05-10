import NixParserLean

structure Options where
  input : String
  desugar : Bool := false
  eval : Bool := false

def readFile (path : String) : IO (Except String String) := do
  try
    pure (.ok (← IO.FS.readFile path))
  catch err =>
    pure (.error s!"could not read {path}: {err}")

def readInput : List String -> IO (Except String Options)
  | [] => pure (.ok { input := "{ answer = 42; values = [ true null \"nix\" ]; }" })
  | ["--desugar"] =>
      pure (.ok { input := "{ answer = 42; values = [ true null \"nix\" ]; }", desugar := true })
  | ["--eval"] =>
      pure (.ok { input := "{ answer = 42; values = [ true null \"nix\" ]; }", eval := true })
  | ["--file", path] => do
      match ← readFile path with
      | .ok input => pure (.ok { input })
      | .error err => pure (.error err)
  | ["--desugar", "--file", path] => do
      match ← readFile path with
      | .ok input => pure (.ok { input, desugar := true })
      | .error err => pure (.error err)
  | ["--file", path, "--desugar"] => do
      match ← readFile path with
      | .ok input => pure (.ok { input, desugar := true })
      | .error err => pure (.error err)
  | ["--eval", "--file", path] => do
      match ← readFile path with
      | .ok input => pure (.ok { input, eval := true })
      | .error err => pure (.error err)
  | ["--file", path, "--eval"] => do
      match ← readFile path with
      | .ok input => pure (.ok { input, eval := true })
      | .error err => pure (.error err)
  | args => pure (.ok { input := " ".intercalate args })

def printCoreResult (options : Options) (coreExpr : NixParserLean.Core.Expr) : IO UInt32 := do
  match NixParserLean.Core.validate coreExpr with
  | .ok () =>
      if options.eval then
        match NixParserLean.Core.eval coreExpr with
        | .ok value =>
            IO.println (repr value)
            pure 0
        | .error err =>
            IO.eprintln err
            pure 1
      else
        IO.println (repr coreExpr)
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
        IO.println (repr expr)
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
  match NixParserLean.parse options.input with
  | .ok expr => printResult options expr
  | .error err =>
      IO.eprintln err
      pure 1
