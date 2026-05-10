# Nested desugaring proof

The static desugaring proof now reaches one level deeper.

The new theorem covers static paths with at least two segments. If
`staticNames?` sees a path like `a.b...`, then `bindingFromPath` lowers it to a
top-level `a` assignment whose value is a non-recursive attrset containing the
nested tail:

```lean
theorem bindingFromPath_static_nested_tail
```

This is still a small theorem, but it is the first checked statement about the
shape of nested dotted assignments. That matters because dotted Nix bindings
are not just strings; they imply a core tree.

The next proof gap is uniqueness after static merges. TICKET-0022 tracks that
separately so this contribution stays reviewable.
