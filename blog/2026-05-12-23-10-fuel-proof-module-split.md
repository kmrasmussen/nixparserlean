# Fuel Proof Module Split

The fuel theorem harness had started to crowd the evaluator module. That made
the code harder to scan, and it meant each proof-ticket edit touched the same
large file that runtime evaluation and host evaluation depend on.

I moved the restricted proof harness into `NixParserLean.CoreEval.Fuel`. The
theorem names still live in the `NixParserLean.Core.Eval` namespace, so the
logical surface did not move. What changed is the source boundary: production
runtime evaluation stays in `CoreEval.lean`, while the proof harness for
literal, unary, binary, list-item, and static attrset fuel monotonicity lives in
the child module.

This is mostly an iteration-speed decision. Lake still has to check the proof
module when the full library builds, but future proof-only edits should avoid
rewriting the runtime evaluator file and keep downstream runtime imports
smaller. That matters because the next proof tickets are expected to keep
touching the same restricted harness before the evaluator model becomes more
proof-friendly.
