# TICKET-0007: Partial and Fuel Debt

## Problem
The parser, desugarer, validator, and evaluator rely on `partial` definitions,
and evaluation uses fuel for recursive lookup.

## Goal
Inventory and reduce termination debt without blocking language coverage.

## In Scope
- Document every `partial` cluster and why it exists.
- Replace simple recursive list walkers with total definitions where Lean can
  see structural recursion. The desugaring attrpath helpers have already moved
  to total `def`s; remaining low-risk examples include:
  - `CoreEval.lean`: `paramEntryNames`, `containsName`, `findExtraAttr?`,
    and the `beq*` helpers.
  - validator/evaluator list walks that currently sit inside larger `partial`
    mutual clusters and may need to be split before they become total.
- Decide where fuel is semantic and where it is implementation debt.
  `defaultFuel = 200` is now exposed through `--fuel N`, but the counter still
  only decrements on thunk forces rather than on every evaluation step.

## Out of Scope
- Rewriting the parser wholesale.
- Proving termination for all Nix evaluation.

## Acceptance Criteria
1. A documented inventory exists.
2. At least one low-risk `partial` cluster is removed.
3. Fuel behavior is covered by an eval failure fixture where relevant.
