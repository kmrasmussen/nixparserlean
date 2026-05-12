# TICKET-0045: Fuel Monotonicity for Literals and Binary Expressions

## Problem
Evaluator fuel now has an entry-step policy, but monotonicity is not proven.

## Goal
State and prove the first fuel monotonicity theorem for a small evaluator
subset.

## In Scope
- Restrict the theorem to literals and binary expressions over supported
  primitive values.
- Add helper predicates or subset definitions if needed.
- Keep theorem assumptions explicit.
- Add docs explaining why closures, thunks, and host imports are excluded.

## Out of Scope
- Full evaluator monotonicity.
- Small-step semantics.

## Acceptance Criteria
1. A checked theorem states monotonicity for the selected subset.
2. `lake build` passes.
3. Fuel e2e manifests still pass.
4. Docs identify the next widening target.
