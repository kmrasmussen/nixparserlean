# Import and Path Boundary

Path literals are syntax and core values, but they are not evaluator values in
the pure core evaluator yet.

The current boundary is:

- Path literals parse, validate, desugar, and core-validate.
- Evaluating a bare path fails with `eval error: unsupported path values`.
- Evaluating `import <path>` fails with `eval error: unsupported import
  evaluation`.

This is deliberate. Import needs host filesystem IO, path normalization, base
directory policy, and a decision about whether imported files are parsed and
evaluated inside the same pure evaluator or through a separate IO layer. Until
that boundary is designed, the evaluator stays pure and rejects imports
explicitly.

The smoke corpus has parser coverage for `import ./foo.nix` and eval-fail
coverage for a local-file import attempt.
