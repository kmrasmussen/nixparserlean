# Recursive let gets thunks

The evaluator no longer treats `let` as a source-order list of eager bindings.

Core `let` evaluation now builds a recursive environment from lazy thunks. Each
static binding is entered into the environment before any of the binding bodies
are evaluated. Looking up a binding evaluates its thunk in the reconstructed
recursive scope.

That makes later references work:

```nix
let
  x = y + 1;
  y = 41;
in
  x
```

It also handles terminating chains:

```nix
let
  x = y + 1;
  y = z + 1;
  z = 40;
in
  x
```

There is still a guardrail. Lookup carries a stack of active binding names, so
self-recursive cycles fail explicitly:

```nix
let x = x + 1; in x
```

Dynamic let bindings remain unsupported. This is enough to remove the old
source-order workaround and move the evaluator closer to real Nix semantics
without opening the door to uncontrolled nontermination.
