# TICKET-0066: Dynamic Selection Default Policy

## Problem
Static selection defaults lower away, but dynamic-path defaults still use the
core select-default branch. The project needs a clear policy before further
core simplification.

## Goal
Decide whether dynamic selection defaults stay core, lower through a helper, or
need a new missing-selection representation.

## In Scope
- Document the semantic tradeoff in core/desugar docs.
- Add focused fixtures if behavior changes.
- Add a theorem TODO or checked theorem for any behavior-preserving lowering.
- Update roadmap notes.

## Out of Scope
- Full selection semantics proof.
- Dynamic attr evaluation redesign.
- Host imports.

## Acceptance Criteria
1. Dynamic selection-default policy is documented.
2. Any behavior change has desugar/eval coverage.
3. Desugar and eval manifests pass if code changes.
4. Follow-up proof or implementation ticket is concrete if needed.
