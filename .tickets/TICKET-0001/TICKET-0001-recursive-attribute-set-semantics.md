# TICKET-0001: Recursive Attribute Set Semantics

## Problem
The evaluator rejects recursive attribute sets. Real Nix uses `rec { ... }`
heavily, and recursive attrsets are a core semantic feature rather than parser
surface noise.

## Goal
Evaluate a conservative fragment of recursive static attribute sets.

## In Scope
- Static `rec { name = expr; ... }` bindings.
- Attribute lookup inside the recursive scope.
- Cycle detection or fuel exhaustion for self-recursive attributes.
- Eval fixtures for terminating and cyclic cases.

## Out of Scope
- Dynamic recursive attribute names.
- Full fixed-point proof.
- Overlay/final-prev style package semantics.

## Acceptance Criteria
1. A later attribute can be referenced inside the same recursive attrset.
2. A self-recursive attribute fails with a clear `eval error:`.
3. Surface, desugar, eval, and flake checks pass.
