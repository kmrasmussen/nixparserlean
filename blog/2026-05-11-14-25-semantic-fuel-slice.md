# Semantic Fuel Slice

Fuel now counts entries into core expression evaluation instead of only thunk
forces. That gives `--fuel` a clearer policy: one step is spent when
`Core.Eval.eval` starts evaluating an expression constructor. Structural list
and binding walkers do not spend fuel on their own, but they spend fuel when
they evaluate the expressions they contain.

This is still not a full small-step semantics. The budget is an interpreter
budget, but it is deterministic and much closer to a theorem target than the
old thunk-only counter.

The new fuel fixtures pin down three cases:

- fuel zero fails before evaluation starts;
- fuel one is not enough for `1 + 2`;
- fuel two is enough for `1 + 2`, and repeated runs behave the same.

Recursive binding cycle diagnostics remain distinct when the budget is large
enough to reach the recursive force. The next proof target is monotonicity for
a small expression subset: if a literal or binary expression succeeds with fuel
`n`, it should also succeed with any larger fuel.
