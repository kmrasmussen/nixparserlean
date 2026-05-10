# Static merge proofs need transparent merges

The first merge invariant is now checked by Lean.

The static attrset merge helpers used to be `partial`, which made them opaque to
proofs. This change gives the merge cluster an explicit internal fuel bound and
then proves a narrow top-level uniqueness fact:

```lean
theorem mergeBindingInto_static_attrset_collision_preserves_single_name
```

When two same-name static attrset bindings merge, the resulting static binding
name list still has a single top-level name. A companion fuel-helper theorem
records the other important case: if same-name static assignments cannot be
merged as attrsets, the duplicate name remains exposed for validation.

This is still a small theorem, but it moves the merge path from runtime-only
behavior toward proof-visible desugaring structure.
