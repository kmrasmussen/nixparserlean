# TICKET-0075: Builtins Environment Shape

## Problem
The evaluator has no explicit builtins environment, but real Nix code quickly
depends on `builtins` and common primitive functions.

## Goal
Design the first builtins environment shape without conflating pure builtins
with host-effect operations.

## In Scope
- Decide how pure builtins enter `CoreEval`.
- Separate pure builtins from host-backed builtins.
- Pick one or two first pure builtins as future implementation targets.
- Document eval and proof implications.

## Out of Scope
- Implementing the full `builtins` set.
- Import/fetcher builtins.
- Derivation/store semantics.

## Acceptance Criteria
1. A design note names the builtins environment shape.
2. Pure versus host-backed builtins are separated.
3. Follow-up implementation tickets are concrete.
4. Core/eval roadmap docs are updated.
