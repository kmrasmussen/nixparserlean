# With Evaluation

`with` is common in real Nix, especially around package sets:

```nix
with { x = 1; };
x
```

The parser, validator, and core syntax already carried `with`; evaluation was
the missing piece. This change gives `with` a conservative evaluator semantics:
the scope expression must evaluate to an attrset, and the body is evaluated with
those attributes available as fallback names.

The important detail is shadowing. Real Nix lets lexical bindings win over
`with` attributes, so this evaluator appends the `with` scope after the current
environment instead of prepending it. That means:

```nix
let x = 1; in with { x = 2; y = 3; };
x + y
```

evaluates as `1 + 3`, not `2 + 3`.

The new smoke fixtures cover simple fallback lookup, `let` shadowing, lambda
parameter shadowing, and the non-attrset failure case. This keeps the first
model small, while making a heavily used Nix construct executable in the core
pipeline.
