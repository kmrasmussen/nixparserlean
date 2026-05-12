# List Fuel Monotonicity

The fuel proof harness now has its first recursive list walker theorem.

`CoreEval.lean` already had checked monotonicity for primitive literals, binary
expressions over primitive literal operands, and unary expressions over
primitive literals. This slice adds `LiteralUnaryBinaryListItemsSubset` and
`evalLiteralUnaryBinaryListItemsWithFuel_monotone`, covering lists whose
elements are already in that restricted literal/unary/binary subset.

This is deliberately not full evaluator monotonicity. It still excludes
closures, thunks, host imports, selection, conditionals, attrsets, and
recursive environments. The useful step is narrower: the proof surface now
includes a recursive evaluator-style walker without introducing environment
cycles.

The next widening target is non-recursive static attrsets, because that adds
binding structure while still avoiding thunks and host effects.
