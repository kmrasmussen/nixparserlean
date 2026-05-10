# TICKET-0020: Broaden Desugaring Invariant Proofs

## Problem
TICKET-0006 introduced the first checked invariant at the surface-to-core
boundary, but the proof coverage is still narrow. Core validation still checks
many properties at runtime that should eventually be established by construction
or by checked desugaring lemmas.

## Goal
Expand proof coverage around desugaring so the runtime core validator becomes a
backstop rather than the only statement of the invariants.

## In Scope
- Lemmas connecting `staticNames?`, `nestedStaticAssign`, and non-empty static
  paths beyond the top-level binding name.
- Proofs that static dotted paths lower to non-empty nested core assignment
  structure.
- Proof-oriented helpers for static binding uniqueness after merge.

## Out of Scope
- Full parser correctness.
- Full evaluator preservation.
- Eliminating `CoreValidate.lean` outright.

## Acceptance Criteria
1. At least one additional desugaring invariant is proven and checked by
   `lake build`.
2. The proof covers nested static attrpaths, not only the top-level name.
3. Any remaining runtime-only invariant is either justified in documentation or
   tracked by a narrower follow-up ticket.
