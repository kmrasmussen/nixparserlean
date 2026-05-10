# TICKET-0022: Static Merge Uniqueness Proofs

## Problem
Desugaring merges sibling static attrpath assignments, but the uniqueness
properties around `mergeBindingInto` and `mergeBindings` are still runtime
checked rather than proven.

TICKET-0020 proved nested static path shape, not uniqueness after merging.

## Goal
Prove useful invariants about static binding names after desugaring merges.

## In Scope
- Helper predicates for static binding names in core binding lists.
- Lemmas about `mergeBindingInto` preserving or exposing static name
  collisions.
- A first proof connecting surface static path uniqueness to core static
  binding uniqueness for a narrow subset.

## Out of Scope
- Dynamic attribute evaluation.
- Full parser correctness.
- Evaluator preservation.

## Acceptance Criteria
1. At least one merge-related static uniqueness lemma is checked by
   `lake build`.
2. The lemma covers `mergeBindingInto` or `mergeBindings`, not just
   `bindingFromPath`.
3. Any assumptions about dynamic paths are explicit in the theorem statement or
   accompanying documentation.
