# TICKET-0050: Parser Expression Termination Strategy

## Problem
The expression parser is the largest remaining `partial` island. Before
rewriting it, the project needs a concrete termination strategy.

## Goal
Choose and document the parser expression termination approach.

## In Scope
- Compare explicit parser fuel with `decreasing_by` on input length.
- Prototype on one small expression parser level if useful.
- Document expected impact on parser readability and error positions.
- Identify the first implementation ticket.

## Out of Scope
- Full parser conversion.
- Parser combinator replacement.

## Acceptance Criteria
1. Strategy is documented.
2. Prototype, if included, keeps default and external parser manifests stable.
3. Follow-up ticket has a narrow write scope.
