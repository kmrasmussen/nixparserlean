# Import and Path Boundary

Path literals are syntax and core values, but they are not evaluator values in
the pure core evaluator yet. Imports cross an explicit host IO boundary instead
of becoming a pure core primitive.

The current boundary is:

- Path literals parse, validate, desugar, and core-validate.
- Evaluating a bare path fails with `eval error: unsupported path values`.
- Pure `--eval` rejects `import <path>` with `eval error: unsupported import
  evaluation`.
- `--eval-imports` resolves relative `./...` and `../...` imports from the
  importing file's directory, reads the target file, parses/validates/desugars
  it, evaluates it in isolation, and reifies representable values before the
  final pure evaluation pass.

This is deliberate. Import needs host filesystem IO, path normalization, base
directory policy, and a decision about how much Nix path behavior to model.
The first boundary keeps `CoreEval` pure and puts filesystem effects in
`HostEval.lean`.

The smoke corpus has parser coverage for `import ./foo.nix`, pure eval-fail
coverage for an import attempt, and `e2e/import-manifest.txt` coverage for the
explicit host IO path.
