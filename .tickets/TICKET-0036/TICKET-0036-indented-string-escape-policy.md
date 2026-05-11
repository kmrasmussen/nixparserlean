# TICKET-0036: Indented String Escape Policy

## Problem
The external corpus has an `indented-string-escape` blocker around literal
content like `''${path}` inside an indented string. The parser supports
indented strings and interpolation, but not the full Nix escape policy.

## Goal
Define and implement the next small indented-string escape layer needed by the
external corpus.

## In Scope
- Add a small fixture matrix for indented string escape/interpolation cases.
- Implement the minimal escape behavior needed by the pinned blocker.
- Document quoted vs. indented string escape support in `docs/parser.md`.
- Update the external manifest row.

## Out of Scope
- Complete Nix string-context semantics.
- Evaluator string coercion changes unless required by the fixture.

## Acceptance Criteria
1. The specific external blocker advances.
2. Smoke fixtures cover literal escaped interpolation and ordinary
   interpolation.
3. Existing string interpolation eval fixtures still pass.
4. Parser docs describe the supported escape subset.
