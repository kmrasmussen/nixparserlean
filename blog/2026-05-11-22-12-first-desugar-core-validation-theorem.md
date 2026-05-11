# First Desugar/Core-Validation Theorem

The first bridge theorem from desugaring into core validation is deliberately
small:

```lean
bindingFromPath_single_static_null_core_valid
```

It proves that a singleton static attrpath with a non-empty name desugars into
a one-binding core attrset accepted by `Core.validate`.

The theorem excludes dynamic paths, nested paths, duplicate bindings,
non-null values, recursive attrsets, and the full surface validator. That is a
feature of this slice: it gives later proof work a checked foothold without
pretending to solve full preservation.

`lake build`, the desugar manifest, and the eval manifest all pass with the new
theorem.

