# TICKET-0029: Desugar Soundness First Theorem

## Problem
The project now has surface validation, desugaring, and core validation, but
the relationship between those layers is still enforced only by tests. The
mission calls for Lean to prove that the model's phases preserve useful
invariants.

## Goal
State and prove the first useful theorem connecting surface validation,
desugaring, and core validation.

## In Scope
- Choose a small theorem statement that can land incrementally, such as:
  "for this restricted class of surface expressions, successful desugaring
  produces core that passes core validation."
- Start with static attrsets and inherit lowering if the full language is too
  large.
- Replace the empty-path fallback in desugaring with an impossible input,
  explicit error, or supporting lemma.
- Add theorem-oriented helper definitions only where they reduce proof
  complexity.
- Document what the theorem does and does not cover.

## Out of Scope
- Full semantic preservation of evaluation.
- Parser correctness.
- Total parser termination.

## Acceptance Criteria
1. At least one checked theorem relates desugaring output to a core invariant.
2. The theorem covers a real desugaring behavior already used by fixtures,
   not a toy duplicate of existing code.
3. The unreachable empty-path fallback in `Desugar.bindingFromPath` is removed,
   rejected explicitly, or justified by a checked lemma.
4. `lake build` passes with the theorem enabled.
5. A blog note explains why this is the first proof target and what remains.
