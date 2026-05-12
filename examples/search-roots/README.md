# Search Roots

This directory contains repo-local roots for explicit angle import tests.

The first root, `demo/`, is used by `e2e/import-search-path-manifest.txt` with:

```sh
lake exe nixparserlean --eval-imports \
  --search-path demo=examples/search-roots/demo \
  --file e2e/corpus/smoke/eval-host-import-angle-search-path.nix
```

The fixture deliberately avoids `NIX_PATH`, system `<nixpkgs>`, network
fetchers, and store realization. It only proves the explicit host search-path
lane.
