import NixParserLean

def main (args : List String) : IO UInt32 := do
  let input := " ".intercalate args
  let input := if input.isEmpty then "{ answer = 42; values = [ true null \"nix\" ]; }" else input
  match NixParserLean.parse input with
  | .ok expr =>
      IO.println (repr expr)
      pure 0
  | .error err =>
      IO.eprintln err
      pure 1
