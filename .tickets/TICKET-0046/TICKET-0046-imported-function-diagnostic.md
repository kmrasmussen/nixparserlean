# TICKET-0046: Imported Function Diagnostic

## Problem
`--eval-imports` rejects imported closures because host import reification
cannot turn closures back into core expressions. This is expected, but the
diagnostic and fixture coverage should make the boundary explicit.

## Goal
Add stable fixture coverage and documentation for imported function rejection.

## In Scope
- Add an imported file that evaluates to a function.
- Add an `eval-fail` import manifest row.
- Improve the diagnostic if needed.
- Update host import docs and flagged caveat.

## Out of Scope
- Supporting imported functions.
- Host-aware evaluator redesign.

## Acceptance Criteria
1. Imported function rejection is covered by `e2e/import-manifest.txt`.
2. The failure is classified as `eval-fail`, not `other-fail`.
3. Docs explain the closure reification boundary.
