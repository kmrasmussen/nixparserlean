# TICKET-0063: Nonrecursive Static Attrset Fuel Monotonicity

## Problem
Attrsets are central to Nix, but evaluator fuel proofs have not reached even a
restricted nonrecursive attrset subset.

## Goal
State and prove, or at minimum state with supporting helpers, monotonicity for
nonrecursive static attrsets with primitive restricted values.

## In Scope
- Define a restricted nonrecursive static attrset subset.
- Prove monotonicity if the helper shape is small enough.
- If proof is too large, land the subset definitions and theorem statement with
  a precise blocker note.
- Add docs explaining excluded dynamic and recursive cases.

## Out of Scope
- Recursive attrsets and thunks.
- Dynamic attr paths.
- Host imports.
- Full preservation.

## Acceptance Criteria
1. The restricted subset is defined in Lean.
2. Either a checked theorem lands or the theorem statement and blocker are
   documented precisely.
3. `lake build` passes.
4. Fuel/eval manifests pass if executable behavior changes.
5. Docs identify the next proof dependency.
