# String Interpolation Evaluates

String interpolation is now part of the evaluator's conservative core:

```nix
let
  name = "demo";
  kind = "package";
in
  "${kind}-${name}"
```

This evaluates to:

```text
NixParserLean.Core.Eval.Value.str "package-demo"
```

The chosen coercion rule is intentionally narrow. Direct interpolation accepts
only values that already evaluate to strings. Integers, booleans, null, attrsets,
lists, paths, and closures are rejected unless a later slice adds an explicit
coercion mechanism.

That matches the important shape of Nix's direct interpolation behavior: plain
integers and booleans are not silently coerced inside `${...}`. Full Nix
`toString`, path coercion, derivation string contexts, and builtins remain out
of scope for this evaluator layer.

Dynamic attribute names now reuse the same string-part evaluation path, with
their existing `dynamic attribute interpolation expects a string` diagnostic.
The smoke fixtures cover supported string interpolation plus integer and
attrset failure cases.
