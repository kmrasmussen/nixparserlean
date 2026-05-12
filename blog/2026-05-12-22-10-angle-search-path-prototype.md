# Angle Search Path Prototype

`--eval-imports` now has a first explicit angle search-path lane.

The new CLI flag is repeatable:

```sh
lake exe nixparserlean --eval-imports \
  --search-path demo=examples/search-roots/demo \
  --file e2e/corpus/smoke/eval-host-import-angle-search-path.nix
```

The mapping key is the first component inside angle brackets. The smoke
fixture imports `<demo/default.nix>`, resolves it under the repo-local
`examples/search-roots/demo` root, and evaluates the imported attrset through
the same host import pipeline used by relative imports.

The boundary remains explicit:

- pure `CoreEval` has no filesystem or search-path behavior;
- unconfigured angle imports still fail in the regular import manifest;
- no ambient `NIX_PATH`, system `<nixpkgs>`, network fetchers, or store
  realization are modeled.

The flake check now includes the focused search-path import manifest, so the
configured success case and the no-search-path rejection stay separate.
