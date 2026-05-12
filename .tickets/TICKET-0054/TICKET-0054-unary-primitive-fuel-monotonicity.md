# TICKET-0054: Unary Primitive Fuel Monotonicity

## Problem
The first checked fuel monotonicity theorem covers primitive literals and
binary expressions whose operands are primitive literals. Unary expressions are
the next smallest widening step.

## Goal
Extend the total evaluator-fuel proof harness with unary expressions over
primitive literals and prove that successful results are preserved with extra
fuel.

## In Scope
- Extend the restricted proof harness in `NixParserLean/CoreEval.lean`.
- Cover supported unary operations over primitive literal operands.
- Keep theorem assumptions explicit and theorem names restriction-aware.
- Update fuel/proof docs and roadmap notes.
- Add or adjust focused fuel e2e coverage if useful.

## Out of Scope
- Full evaluator monotonicity.
- Lists, attrsets, selection, conditionals, closures, thunks, or host imports.
- A small-step semantics.

## Acceptance Criteria
1. A checked theorem states monotonicity for the unary primitive subset.
2. `lake build` passes.
3. Fuel e2e manifests pass.
4. Eval manifest passes.
5. Docs identify the next widening target.
