# TICKET-0060: Core `with` Decision

## Problem
`with` remains a core expression form. It may be a permanent environment
operation, or it may need to lower away before serious preservation proofs.

## Goal
Decide whether `with` is permanent core syntax or should lower into a smaller
explicit environment representation.

## In Scope
- Document the decision in `docs/core.md` and `roadmap/03-core-semantics.md`.
- If behavior changes, add desugar/eval fixtures.
- If behavior does not change, state the core invariant expected of `with`.
- Add a follow-up ticket if implementation is deferred.

## Out of Scope
- Full environment semantics proof.
- Reworking lambdas or recursive thunks.
- Host import behavior.

## Acceptance Criteria
1. The roadmap and core docs name the decision.
2. Any behavior change has e2e coverage.
3. Eval/desugar manifests pass if implementation changes.
4. A concrete follow-up exists if the decision requires later code work.
