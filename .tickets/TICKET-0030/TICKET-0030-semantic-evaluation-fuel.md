# TICKET-0030: Semantic Evaluation Fuel

## Problem
Evaluation fuel is configurable and tested, but it currently behaves mainly
as a thunk-forcing limit. That is enough to prevent runaway recursion, but it
is not yet a semantic step budget that can support monotonicity or
determinism statements.

## Goal
Redesign evaluator fuel as an explicit semantic budget for supported core
evaluation steps.

## In Scope
- Define what one fuel step means for the current evaluator.
- Make recursive calls consume fuel consistently enough to state useful
  monotonicity expectations.
- Keep cycle detection diagnostics stable.
- Add fixtures that distinguish ordinary evaluation budget exhaustion from
  recursive binding cycles.
- Document the relationship between fuel, laziness, and thunk forcing.

## Out of Scope
- Proving termination of arbitrary Nix evaluation.
- A full small-step semantics in the first implementation slice.
- Performance optimization.

## Acceptance Criteria
1. Fuel consumption is documented as a semantic policy rather than an
   implementation accident.
2. `--fuel` behavior remains deterministic across repeated runs.
3. Existing recursive-cycle fixtures still fail with cycle diagnostics rather
   than generic fuel exhaustion where appropriate.
4. New e2e fixtures cover budget exhaustion for non-trivial successful and
   failing expressions.
5. The roadmap identifies the next theorem target after semantic fuel lands.
