# Example Suite Split

The old `current-core-showcase` example remains useful as a dense integration
case, but it is no longer the only example surface.

The new focused suite under `examples/` splits supported behavior into smaller
regression specs:

- pure expressions;
- terminating recursion;
- attrset lambdas with aliases/defaults/ellipsis;
- dynamic attributes;
- explicit host import boundary;
- proof-oriented static attrsets.

Each directory has its own README and each `.nix` example is referenced from an
e2e manifest. The host-boundary example goes through `e2e/import-manifest.txt`,
the static attrset proof fragment goes through `e2e/desugar-manifest.txt`, and
the pure evaluator examples go through `e2e/eval-manifest.txt`.

`nix flake check` passes with the new examples staged, which also confirmed
that flake checks need new source files tracked before the Nix source snapshot
can see them.
