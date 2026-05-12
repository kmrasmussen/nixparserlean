# TICKET-0062: List Fuel Monotonicity

## Problem
Fuel monotonicity is only proven for primitive literals and primitive-literal
binary expressions. Lists are the next useful structural subset.

## Goal
Prove monotonicity for lists whose elements are already in the restricted
primitive expression subset.

## In Scope
- Extend or add a total proof harness for primitive-list evaluation.
- Prove extra fuel preserves successful list results.
- Keep the theorem restriction explicit.
- Update proof/fuel docs.

## Out of Scope
- Lists containing thunks, closures, host imports, selection, or recursive
  attrsets.
- Full evaluator monotonicity.
- Small-step semantics.

## Acceptance Criteria
1. A checked theorem states list monotonicity for the restricted subset.
2. `lake build` passes.
3. Fuel manifests pass.
4. Eval manifest passes.
5. Docs name the next widening target.
