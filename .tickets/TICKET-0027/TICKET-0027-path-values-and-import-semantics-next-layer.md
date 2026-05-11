# TICKET-0027: Path Values and Import Semantics Next Layer

## Problem
The project has a clean first host import boundary, but imports are eager,
relative-only, and value-only. Bare path expressions still fail in the pure
evaluator, and imported functions cannot be represented because closures are
not reified back into core expressions.

## Goal
Define and implement the next small semantic layer for paths and imports
without blurring the pure evaluator / host IO boundary.

## In Scope
- Decide how path values should appear in `Core.Eval.Value`.
- Evaluate bare path literals as values, with a clear policy for relative,
  absolute, home, angle, and store-like paths.
- Preserve pure `--eval` as filesystem-free.
- Extend `--eval-imports` only where the semantics are explicit and covered
  by fixtures.
- Investigate whether imported functions should remain closures, be rejected
  with better diagnostics, or require a different import evaluation shape.

## Out of Scope
- Network fetchers.
- Store realization.
- Nix search path resolution for `<nixpkgs>` unless explicitly designed as a
  follow-up.
- Full laziness for imports if it would require a broad evaluator rewrite.

## Acceptance Criteria
1. Bare path value behavior is represented in `Core.Eval.Value` or rejected
   by a documented design choice stronger than the current placeholder.
2. Existing host import fixtures keep passing.
3. Unsupported import/path forms remain classified as `eval-fail`, not
   `other-fail`.
4. `flagged.md` is updated to remove or narrow the current path/import caveats.
5. `docs/import-and-path-boundary.md` explains the new boundary precisely.
