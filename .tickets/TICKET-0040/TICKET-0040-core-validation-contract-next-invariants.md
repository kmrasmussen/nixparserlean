# TICKET-0040: Core Validation Contract Next Invariants

## Problem
Core validation is an executable contract and a future theorem target. It needs
to grow intentionally rather than mirroring surface validation indefinitely.

## Goal
Add or document the next core invariant that helps evaluation and proof work.

## In Scope
- Audit current core invariants against evaluator assumptions.
- Add one narrow invariant if it catches a real unsupported core shape.
- Add a `core-fail`, desugar, or eval fixture as appropriate.
- Document the invariant in `docs/core.md`.

## Out of Scope
- Replacing core validation with proofs.
- Broad validator redesign.

## Acceptance Criteria
1. The new or clarified invariant is documented.
2. A fixture covers the invariant if behavior changes.
3. Core-validation manifest or relevant e2e manifest passes.
