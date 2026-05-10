# TICKET-0007: Partial and Fuel Debt

## Problem
The parser, desugarer, validator, and evaluator rely on `partial` definitions,
and evaluation uses fuel for recursive lookup.

## Goal
Inventory and reduce termination debt without blocking language coverage.

## In Scope
- Document every `partial` cluster and why it exists.
- Replace simple recursive list walkers with total definitions.
- Decide where fuel is semantic and where it is implementation debt.

## Out of Scope
- Rewriting the parser wholesale.
- Proving termination for all Nix evaluation.

## Acceptance Criteria
1. A documented inventory exists.
2. At least one low-risk `partial` cluster is removed.
3. Fuel behavior is covered by an eval failure fixture where relevant.
