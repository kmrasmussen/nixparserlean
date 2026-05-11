# Total Desugar Walk

The main surface-to-core desugaring walk no longer uses `partial`.

The public API is unchanged:

```lean
def desugar (surface : Expr) : Except String Core.Expr
```

Internally, the walk now uses `defaultDesugarFuel = 100000` and total
fuel-bounded helpers for expressions, bindings, string parts, attribute paths,
lambda parameters, and lists. Fuel exhaustion reports:

```text
desugar error: fuel exhausted
```

This mirrors the validator strategy: use explicit fuel to remove the broad
opaque recursion first, then prove sufficient-fuel facts for restricted subsets
later.

`lake build`, the desugar manifest, and the eval manifest pass with the fuelled
walk.

