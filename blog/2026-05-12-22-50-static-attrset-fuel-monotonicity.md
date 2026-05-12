# Static Attrset Fuel Monotonicity

The fuel proof harness now reaches a narrow non-recursive static attrset
fragment.

This slice adds total helpers for evaluating static attrset binding lists whose
values are already in the literal/unary/binary proof subset. The checked
theorems show that successful evaluation through this restricted helper is
preserved when extra fuel is available.

The restriction is important. This does not model recursive attrsets, thunks,
dynamic bindings, inherited bindings, host imports, selection, conditionals, or
full production evaluator preservation. It only adds binding structure on top
of the already checked primitive expression subset.

The next proof step should be determinism modulo fuel for the same restricted
harnesses before widening into more evaluator behavior.
