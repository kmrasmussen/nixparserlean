# Low-Risk Totality

The totality work made a small but useful move: evaluator helpers that are just
structural recursion are no longer hidden behind `partial`.

The changed helpers are:

- `beqValue`, `beqValues`, and `beqAttrs`;
- `equalValue`, `equalValues`, and `equalAttrs`;
- `paramEntryNames`, `containsName`, and `findExtraAttr?`.

The parameter helpers had to move out of the large evaluator mutual block.
Lean does not allow non-partial definitions to live inside the same mutual
cluster as the partial evaluator, so isolating them made their simple
termination argument visible.

I also tested the next tempting step: making the surface and core validators
total. Lean rejected both mutual blocks for the same useful reason. The
validators recurse through derived lists such as `path.exprs` and
`paramSet.entries`, and Lean cannot infer that those lists are smaller than the
parent syntax node without an explicit measure or a different validator shape.

That is now documented as the Phase 2 obstacle rather than left as a vague
"partial remains" note.
