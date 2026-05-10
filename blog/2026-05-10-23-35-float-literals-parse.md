# Float literals parse

The parser now recognises common Nix float literal shapes:

```nix
1.0
3.14
1e6
2.5e-3
```

Floats are represented as `Expr.float String` in the surface AST and
`Core.Expr.float String` after desugaring. The string preserves the source
spelling while we defer the bigger semantic decision: exact decimal, Lean
`Float`, or some future numeric representation.

The evaluator rejects floats for now with:

```text
eval error: unsupported float values
```

That is intentional and covered by an eval-fail fixture. TICKET-0021 now tracks
the follow-up evaluator policy for float values and arithmetic.

One important parser ambiguity is preserved: `1.foo` is still an attribute
selection on the integer literal `1`, because a decimal float requires digits
after the dot.
