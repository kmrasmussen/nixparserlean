import NixParserLean

structure Options where
  input : String
  desugar : Bool := false

def readFile (path : String) : IO (Except String String) := do
  try
    pure (.ok (← IO.FS.readFile path))
  catch err =>
    pure (.error s!"could not read {path}: {err}")

def readInput : List String -> IO (Except String Options)
  | [] => pure (.ok { input := "{ answer = 42; values = [ true null \"nix\" ]; }" })
  | ["--desugar"] =>
      pure (.ok { input := "{ answer = 42; values = [ true null \"nix\" ]; }", desugar := true })
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
  | args => pure (.ok { input := " ".intercalate args })

def printResult (options : Options) (expr : NixParserLean.Expr) : IO UInt32 := do
  match NixParserLean.validate expr with
  | .ok () =>
      if options.desugar then
        match NixParserLean.desugar expr with
        | .ok coreExpr =>
            IO.println (repr coreExpr)
            pure 0
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
