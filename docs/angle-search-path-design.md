# Angle Search Path Design

Angle paths such as `<nixpkgs>` currently parse as path literals and are
rejected in import position. Supporting them should be host-backed and
deterministic, not an implicit read from the user's machine.

## Proposed Interface

Add an explicit search-path input to the host import lane:

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

## First Implementation Slice

1. Extend CLI parsing with repeatable `--search-path NAME=PATH`.
2. Thread the mapping into `HostEval.resolveImportPath`.
3. Add repo-local fixtures under `examples/search-roots/`.
4. Keep the existing angle-import rejection fixture for the no-search-path case.

This design intentionally does not cover network fetchers, store realization,
or system `<nixpkgs>` discovery.

