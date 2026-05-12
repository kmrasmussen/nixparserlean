# TICKET-0061: Angle Search Path Prototype

## Problem
Angle paths parse as path literals and are rejected in import position. The
search-path design now exists, but there is no implementation.

## Goal
Implement explicit repo-local angle import resolution through a repeatable
`--search-path NAME=PATH` host option.

## In Scope
- Add CLI parsing for repeatable `--search-path NAME=PATH`.
- Thread the mapping through the host import lane.
- Resolve `<name>` and `<name/rest>` from the explicit mapping.
- Add repo-local search-root fixtures.
- Preserve no-search-path angle rejection.

## Out of Scope
- Implicit `NIX_PATH`.
- Network fetchers.
- Store realization.
- Pure evaluator filesystem behavior.

## Acceptance Criteria
1. A repo-local angle import succeeds with explicit `--search-path`.
2. The existing no-search-path rejection remains tested.
3. Import manifest passes.
4. Help output documents the new option.
5. `CoreEval.lean` remains filesystem-free.

## Resolution

Implemented a repeatable `--search-path NAME=PATH` CLI option and threaded the
mapping through `HostEval.resolveImports`. Angle imports are resolved only in
the host import lane, using the first component inside `<...>` as the search
path key. Relative imports still use the existing base-directory behavior.

Added a repo-local `examples/search-roots/demo/default.nix` fixture and
`e2e/import-search-path-manifest.txt` for the configured success case. The
existing no-search-path angle import remains an expected eval failure in
`e2e/import-manifest.txt`.

Updated CLI, host-boundary, core, testing, roadmap, and example documentation.
`CoreEval.lean` remains filesystem-free; search-path and file reads stay in
`HostEval.lean` and the CLI file-input path.

Verification:

- `nix develop -c lake build`
- `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/import-manifest.txt --parser "lake exe nixparserlean --eval-imports --file"`
- `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/import-search-path-manifest.txt --parser "lake exe nixparserlean --eval-imports --search-path demo=examples/search-roots/demo --file"`
- `nix develop -c lake exe nixparserlean --help | rg -- "--search-path|eval-imports|usage"`
- `nix develop -c lake exe nixparserlean --eval-imports --search-path demo=examples/search-roots/demo --file e2e/corpus/smoke/eval-host-import-angle-search-path.nix`
