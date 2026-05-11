# Host Boundary

`main.nix` uses `import ./imported.nix`, which is intentionally outside pure
`--eval` but supported by the explicit `--eval-imports` host layer.

It is referenced by `e2e/import-manifest.txt`.
