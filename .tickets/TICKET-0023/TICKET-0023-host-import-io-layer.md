# TICKET-0023: Host Import IO Layer

## Problem
TICKET-0005 makes import rejection explicit, but real import evaluation needs a
host IO boundary rather than pure `CoreEval` pretending filesystem access is a
normal expression.

## Goal
Design and implement the first host-side import evaluator path.

## In Scope
- Decide where source file base directories live.
- Parse imported files through the existing parser/validator/desugar pipeline.
- Keep pure core evaluation separate from host IO orchestration.
- Add local import fixtures that evaluate successfully.

## Out of Scope
- Network fetchers.
- Store path realisation.
- Full Nix path canonicalisation.

## Acceptance Criteria
1. A local `import ./file.nix` fixture evaluates successfully through an
   explicit IO-aware path.
2. Pure `CoreEval` remains usable without filesystem access.
3. Unsupported import/path cases still emit classified `eval error:` messages.

## Resolution
Implemented an explicit `--eval-imports` CLI path backed by
`NixParserLean/HostEval.lean`. The host layer resolves only relative path
imports (`./...` and `../...`) from the importing file's directory, reads the
target through `IO.FS.readFile`, runs the existing parse/validate/desugar/core
validation pipeline, evaluates the imported file in isolation, and injects
representable values back into the core expression before the normal pure
evaluator runs.

Pure `--eval` still uses `CoreEval` directly and still rejects imports.

Current limitations are deliberate:

- angle paths, home paths, absolute path policy, store paths, and network
  fetchers remain unsupported and produce `eval error:` diagnostics.
- imported closures cannot be reified back into core expressions yet, so
  importing a file that evaluates to a function is still rejected.
- imports are resolved before the final evaluation pass, so the first host
  path is not a lazy import semantics.

Coverage lives in `e2e/import-manifest.txt`, run with
`lake exe nixparserlean --eval-imports --file`.
