# Current Core Showcase

The smoke fixtures are good for regression coverage, but they do not tell a new
reader what the project can do today. This slice adds a small `examples/`
showcase that is meant to be read by humans and executed by CI.

The example lives at:

```text
examples/current-core-showcase/showcase.nix
```

It evaluates to `84` and combines several features that recently became real
evaluator behavior:

- recursive attrsets
- aliased attrset parameters
- defaults that read through the alias
- dynamic quoted attribute names
- attribute selection
- `with` fallback lookup

The key choice is that the exact same `.nix` file is included in
`e2e/eval-manifest.txt`. That makes the showcase a regression test, not just
documentation. If the README says the example works, the e2e suite now enforces
that it keeps working.

This gives the repository a better front door while preserving the existing
discipline: examples should be executable, and impressive demos should still be
reviewable test cases.
