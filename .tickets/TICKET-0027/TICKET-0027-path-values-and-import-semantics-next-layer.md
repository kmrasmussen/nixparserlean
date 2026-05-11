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

## Plan
1. Represent path values directly in `Core.Eval.Value`.
2. Keep path evaluation inert: preserve parsed text and perform no filesystem
   IO, normalization, store copying, or search-path lookup.
3. Reify imported path values back to core expressions in the host import lane.
4. Add e2e fixtures for pure path values, path equality, imported path values,
   and unsupported absolute/home/angle import forms.
5. Update the import/path boundary docs, `flagged.md`, and the project log.

## Resolution
Path literals now evaluate to `Core.Eval.Value.path` and preserve their parsed
text. This applies to relative, absolute, home, angle, and store-like path
syntax. Pure evaluation remains filesystem-free: path values do not check
existence, normalize, copy to the store, or resolve angle paths.

The host import lane remains explicit. `--eval-imports` still only resolves
relative `./...` and `../...` import arguments, but imported representable
values can now include inert paths because `HostEval.valueToExpr` reifies path
values back into core expressions.

Unsupported absolute, home-relative, and angle imports remain expected
`eval-fail` cases.

Verification:

```text
lake build: pass
e2e/manifest.txt: 36 passed, 3 expected parse failures, 8 expected validation failures
e2e/eval-manifest.txt: 41 passed, 20 expected eval failures
e2e/import-manifest.txt: 3 passed, 3 expected eval failures
e2e/json-manifest.txt: 1 passed
lake exe nixparserlean --eval --format json --file e2e/corpus/smoke/eval-path-values.nix: pass
nix flake check: pass on x86_64-linux
```
