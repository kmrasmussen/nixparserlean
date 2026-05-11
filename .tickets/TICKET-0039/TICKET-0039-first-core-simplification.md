# TICKET-0039: First Core Simplification

## Problem
Core still carries several surface-like constructs. A smaller core will make
evaluation and proof work easier, but the first simplification needs to be
behavior-preserving and well-tested.

## Goal
Lower one selected surface-like form into a smaller core representation.

## In Scope
- Choose one form from the minimal-core classification, such as `assert`,
  `with`, or selection defaults.
- Update desugaring and any evaluator/core-validation code needed.
- Add focused desugar/eval fixtures.
- Add a small theorem or theorem TODO documenting the preservation claim.

## Out of Scope
- Multiple unrelated core simplifications.
- Host import semantics.

## Acceptance Criteria
1. One core constructor or behavior path is simplified.
2. Existing eval fixtures still pass.
3. New desugar/eval fixtures cover the changed lowering.
4. Docs explain the new core shape.
