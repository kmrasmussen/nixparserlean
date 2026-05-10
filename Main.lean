import NixParserLean

def readInput : List String -> IO (Except String String)
  | [] => pure (.ok "{ answer = 42; values = [ true null \"nix\" ]; }")
  | ["--file", path] => do
      try
        pure (.ok (← IO.FS.readFile path))
      catch err =>
        pure (.error s!"could not read {path}: {err}")
  | args => pure (.ok (" ".intercalate args))

def main (args : List String) : IO UInt32 := do
  match ← readInput args with
  | .error err =>
      IO.eprintln err
      pure 1
  | .ok input =>
  match NixParserLean.parse input with
  | .ok expr =>
      IO.println (repr expr)
      pure 0
  | .error err =>
      IO.eprintln err
      pure 1
