# Angle Search Path Design

Angle paths such as `<nixpkgs>` currently parse as path literals and are
rejected in import position. Supporting them should be host-backed and
deterministic, not an implicit read from the user's machine.

## Interface

The host import lane accepts explicit, repeatable search-path inputs:

```sh
lake exe nixparserlean --eval-imports \
  --search-path nixpkgs=examples/search-roots/nixpkgs \
  --file example.nix
```

The mapping key is the first path component inside angle brackets. `<nixpkgs>`
resolves to the mapped directory. `<nixpkgs/lib/default.nix>` resolves to the
mapped directory joined with `lib/default.nix`.

## Semantics

- Pure `CoreEval` remains filesystem-free.
- Angle imports are supported only by the explicit host layer.
- If a key is missing, the diagnostic should stay an `eval error:`.
- Search roots in tests must be repo-local fixtures.
- Do not read `NIX_PATH` or any ambient system search path by default.
- Resolved files should go through the same parse, validate, desugar,
  core-validate, evaluate, and reify pipeline as relative imports.

## Implemented Slice

The first implementation slice is intentionally narrow:

1. CLI parsing accepts repeatable `--search-path NAME=PATH`.
2. The mapping is threaded into `HostEval.resolveImportPath`.
3. Repo-local fixtures live under `examples/search-roots/`.
4. `e2e/import-search-path-manifest.txt` covers configured angle import
   success.
5. `e2e/import-manifest.txt` keeps the no-search-path angle-import rejection.

This design intentionally does not cover network fetchers, store realization,
or system `<nixpkgs>` discovery.
