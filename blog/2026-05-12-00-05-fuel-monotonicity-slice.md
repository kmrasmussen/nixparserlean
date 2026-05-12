# Fuel Monotonicity Slice

The first evaluator-fuel theorem is now checked, but it is intentionally small.

The new proof harness in `CoreEval.lean` covers primitive literals and binary
expressions whose operands are already primitive literals. That is the fragment
where the current entry-step fuel policy is easiest to state: literals need one
entry, and binary expressions over literal operands need two entries. The theorem
`evalLiteralBinarySubsetWithFuel_monotone` says that a successful result at the
base cost is preserved when extra fuel is added.

This does not claim full evaluator monotonicity. Closures, thunks, host imports,
selection, lists, attrsets, and conditionals are deliberately outside the proof
until the environment-facing recursion has better invariants. The next useful
widening target is unary expressions over primitive literals, then lists and
non-recursive attrsets.

The e2e fuel manifests now include a high-fuel pass for the arithmetic smoke, so
the runtime suite also checks that extra fuel preserves the primitive binary
result.
