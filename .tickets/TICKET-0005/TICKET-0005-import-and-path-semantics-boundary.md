# TICKET-0005: Import and Path Semantics Boundary

## Problem
Path literals parse, and `import ./file.nix` parses as application, but the
evaluator rejects path values and function application cannot model imports.

## Goal
Design and implement a safe first boundary for path values and imports.

## In Scope
- Decide whether import belongs in core syntax, an eval primitive, or host IO.
- Text fixture imports under `e2e/corpus/smoke`.
- Explicit errors for unsupported filesystem cases.

## Out of Scope
- Full Nix path normalization.
- Store paths and fetchers.
- Network access.

## Acceptance Criteria
1. The import boundary is documented.
2. A simple local-file import can be evaluated or explicitly rejected by design.
3. The evaluator remains pure unless a deliberate IO layer is introduced.
