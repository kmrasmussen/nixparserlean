# TICKET-0021: Float Evaluation Semantics

## Problem
TICKET-0017 adds float literals to the surface and core AST, but evaluation
still rejects `.float` values with `eval error: unsupported float values`.

The project needs a deliberate policy before arithmetic, equality, and string
interpolation can treat floats as values.

## Goal
Define and implement the first evaluator semantics for floats.

## In Scope
- Decide whether core float values store source text, Lean `Float`, or a more
  precise decimal representation.
- Evaluate float literals to a `Value.float` form.
- Define arithmetic behaviour for float-only operators.
- Decide whether mixed int/float arithmetic coerces or fails.
- Add eval fixtures for accepted float arithmetic and rejected mixed cases.

## Out of Scope
- IEEE-754 proof work.
- Exact decimal arithmetic proofs.
- Nix string-context semantics.

## Acceptance Criteria
1. Float literals evaluate to an explicit value form.
2. Float arithmetic policy is documented in `docs/core.md`.
3. Eval fixtures cover float-only arithmetic and at least one mixed numeric
   case.
