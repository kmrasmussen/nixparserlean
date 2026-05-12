# TICKET-0064: Determinism Modulo Fuel Statement

## Problem
The evaluator is a deterministic function, but the proof roadmap needs a
precise theorem target for successful runs under fuel.

## Goal
State the first determinism modulo fuel theorem for the same restricted subset
covered by the current fuel monotonicity harness.

## In Scope
- Add a theorem statement or checked theorem for the restricted subset.
- Prefer a checked theorem if it is straightforward.
- Document how this will widen alongside monotonicity.
- Keep assumptions explicit.

## Out of Scope
- Full evaluator determinism over thunks and environments.
- Small-step semantics.
- Host imports.

## Acceptance Criteria
1. A determinism theorem target is present in Lean.
2. If not fully proven, the exact proof blocker is documented.
3. `lake build` passes.
4. Proof roadmap docs reference the theorem target.

## Resolution

Added checked same-fuel determinism theorems for the restricted proof harnesses
in `NixParserLean/CoreEval/Fuel.lean`:

- `evalLiteralBinarySubsetWithFuel_deterministic`
- `evalLiteralUnaryBinarySubsetWithFuel_deterministic`
- `evalLiteralUnaryBinaryListItemsWithFuel_deterministic`
- `evalNonrecursiveStaticAttrBindingsWithFuel_deterministic`
- `evalNonrecursiveStaticAttrsetWithFuel_deterministic`

Each theorem says that if the same harness run at the same fuel succeeds with
two values, those values are equal. The proof is intentionally direct because
these harnesses are still executable functions. The useful part is the named
target: future relational or small-step semantics can preserve this statement
while replacing the proof body with a real relation-level argument.

This does not prove full evaluator determinism over thunks, recursive
environments, host imports, or the production `eval` mutual block.

Verification:

- `nix develop -c lake build`
