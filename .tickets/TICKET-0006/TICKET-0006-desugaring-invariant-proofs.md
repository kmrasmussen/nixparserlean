# TICKET-0006: Desugaring Invariant Proofs

## Problem
Core validation checks invariants after desugaring, but we do not yet prove
that desugaring preserves or establishes those invariants.

## Goal
Start proof-oriented coverage for the surface-to-core boundary.

## In Scope
- Small lemmas about static attrpath desugaring.
- Invariants for non-empty paths and static binding uniqueness.
- Replacing some runtime checks with proof-backed construction where practical.

## Out of Scope
- Full parser correctness.
- Full evaluator preservation.

## Acceptance Criteria
1. At least one useful invariant about desugared static bindings is proven.
2. The proof is checked by `lake build`.
3. Remaining proof debt is documented in follow-up tickets.
