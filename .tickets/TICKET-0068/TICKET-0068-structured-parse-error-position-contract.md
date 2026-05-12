# TICKET-0068: Structured Parse Error Position Contract

## Problem
Parse errors include source positions in text form, but the project does not
yet have a structured parse-error contract suitable for larger corpus work.

## Goal
Design the structured parse-error shape and add a first contract fixture or
JSON output check if feasible.

## In Scope
- Document parse error fields: offset, line, column, message, and context.
- Decide how JSON output should represent parse errors.
- Add a focused fixture if implementation lands.
- Preserve current text diagnostics unless intentionally changed.

## Out of Scope
- Full parser error recovery.
- Rich expected-token sets for every parser branch.
- UI/editor integration.

## Acceptance Criteria
1. Structured parse-error contract is documented.
2. Any implementation has focused e2e coverage.
3. Existing parse-fail rows remain classified correctly.
4. JSON manifest passes if JSON behavior changes.
