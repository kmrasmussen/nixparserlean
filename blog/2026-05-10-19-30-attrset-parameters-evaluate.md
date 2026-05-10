# Attribute-set parameters start evaluating

The evaluator now handles a function shape that looks much more like real Nix:

```nix
({ a, b }: a + b) { a = 1; b = 2; }
```

Identifier lambdas gave us closures and lexical scope. Attribute-set parameters
give those closures Nix's common calling convention. The evaluator now checks
that the argument is an attrset, binds required fields into the function body,
and reports missing fields as `eval error`s.

Extra attributes are rejected unless the parameter set includes `...`:

```nix
({ a }: a) { a = 1; b = 2; }      # eval error
({ a, ... }: a) { a = 1; b = 2; } # ok
```

Defaults are still deliberately unsupported. That keeps this slice focused on
required-field destructuring and makes the next semantic step obvious:
evaluating defaults in the right environment.

This moves the evaluator closer to the shapes used by Nix packages and modules,
where functions commonly begin as `{ pkgs, lib, ... }:`.
