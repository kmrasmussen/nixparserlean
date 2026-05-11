# Examples

These examples are small, named regression specs. Each directory has a
`README.md` and at least one `.nix` file referenced by an e2e manifest.

The focused examples are easier to read than the combined showcase:

- `pure-expressions/` covers pure arithmetic, comparison, lists, and attrsets.
- `recursion/` covers terminating recursive `let` and `rec { ... }` behavior.
- `lambdas/` covers attrset lambdas, aliases, defaults, and ellipsis.
- `dynamic-attrs/` covers dynamic attribute binding and selection.
- `host-boundary/` covers explicit `--eval-imports` relative import behavior.
- `proof-static-attrsets/` covers static dotted attrsets used by desugaring and
  proof-oriented invariants.

`current-core-showcase/` remains as a dense combined example that exercises
several features together.
