# TICKET-0008: Structured Parse Errors

## Problem
Parser errors are strings with byte offsets. This is enough for the e2e runner,
but not enough for larger corpus triage or editor-grade diagnostics.

## Goal
Introduce structured parse errors with source positions.

## In Scope
- Error type with offset, message, and eventual line/column.
- Preserve existing `parse error` CLI prefix for runner compatibility.
- Smoke fixtures for key error cases.

## Out of Scope
- Error recovery.
- Multi-error reporting.

## Acceptance Criteria
1. Parser internals return structured errors.
2. CLI output remains compatible with existing e2e classification.
3. At least one fixture asserts behavior through the existing runner.
