# Closures enter the core evaluator

The evaluator can now run simple functions.

The new value form is a closure: an environment, a lambda parameter, and a core
body. Evaluating a lambda captures the current environment. Evaluating an
application evaluates the function and argument, binds an identifier parameter,
and evaluates the body in the closure environment extended with that argument.

That makes these expressions executable:

```nix
(x: x + 1) 41

let
  inc = x: x + 1;
in
  inc 41
```

It also gives the evaluator its first real lexical-scope test:

```nix
let
  base = 40;
  addBase = x: base + x;
in
  addBase 2
```

The slice stays narrow. Attribute-set parameters and aliases still fail with an
explicit `eval error:`. This keeps the evaluator honest while creating the
semantic hook needed for the next step: destructuring function arguments.

One implementation detail is now visible: desugared let bindings currently have
an order chosen by the binding merge pass, so evaluation walks that core list in
reverse to preserve the simple source-order cases covered by the smoke tests.
Real Nix `let` is recursive; replacing this approximation with a proper
recursive environment remains a future semantic step.
