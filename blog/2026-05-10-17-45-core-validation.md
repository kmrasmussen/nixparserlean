# Core validation gives desugaring a contract

The new core language now has its own validation pass.

Surface validation answers source-language questions: duplicate bindings,
conflicting attribute paths, duplicate lambda parameters. Core validation has a
different job. It checks that the desugared target satisfies the invariants that
future evaluation and proofs should be able to assume.

The first pass is intentionally small:

- static core binding names are unique at each binding level
- dynamic assignments have a non-empty path
- selections and attribute existence tests have non-empty paths
- interpolated expressions inside core strings and dynamic path segments are
  recursively valid

The CLI now routes `--desugar` through this pass before printing the core AST.
That means the smoke corpus is not only parsed and validated as surface Nix; it
can also be lowered and checked as core.

This is a modest amount of code, but it changes the engineering shape of the
project. Desugaring is no longer just translation. It has a checked contract.
