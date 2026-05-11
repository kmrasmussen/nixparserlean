# TICKET-0032: Spaced Dynamic Selection Corpus Ratchet

## Problem
The pinned external corpus still has two `spaced-dynamic-selection` parse
blockers. Real nixpkgs code can split selection across whitespace/newlines
before a dynamic selector, while the parser currently keeps selection-dot
handling conservative to avoid confusing `import ./file.nix` with selection.

## Goal
Support the external corpus spaced dynamic selection pattern without regressing
path arguments or import parsing.

## In Scope
- Add smoke fixtures for newline/space before `.${...}` selection.
- Preserve `import ./file.nix` and dot-file path argument behavior.
- Update `e2e/external-manifest.txt` rows for the two current blockers.
- Document the selection/path disambiguation in `docs/parser.md`.

## Out of Scope
- General parser termination work.
- Search path or import semantics.
- Any evaluator semantics beyond successful parsing/desugaring as needed.

## Acceptance Criteria
1. A committed smoke fixture covers spaced dynamic selection.
2. Existing import/path parser fixtures still pass.
3. The two external `spaced-dynamic-selection` rows move to `pass` or to a
   narrower later blocker with updated notes.
4. `docs/parser.md` explains the whitespace-sensitive selection/path boundary.
5. `lake build`, default e2e, and external manifest verification pass.
