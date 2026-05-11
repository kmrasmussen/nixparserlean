# Import and Path Boundary

Path literals are syntax, core expressions, and inert evaluator values. Imports
cross an explicit host IO boundary instead of becoming a pure core primitive.

The current boundary is:

- Path literals parse, validate, desugar, core-validate, and evaluate to
  `Core.Eval.Value.path`.
- Evaluating a bare path performs no filesystem access, path existence check,
  path normalization, store copying, or search-path lookup.
- Relative (`./...`, `../...`), absolute (`/...`), home (`~/...`), angle
  (`<...>`), and store-like (`/nix/store/...`) path literals are preserved as
  their parsed text when used as values.
- Pure `--eval` rejects `import <path>` with `eval error: unsupported import
  evaluation`.
- `--eval-imports` resolves relative `./...` and `../...` imports from the
  importing file's directory, reads the target file, parses/validates/desugars
  it, evaluates it in isolation, and reifies representable values, including
  path values, before the final pure evaluation pass.
- Imported files that evaluate to functions are rejected with
  `eval error: unsupported imported function values`, because closures cannot
  currently be reified back into core syntax for the final pure pass.
- `--eval-imports` still rejects absolute, home-relative, and angle imports.

This is deliberate. Import needs host filesystem IO, path normalization, base
directory policy, and a decision about how much Nix path behavior to model.
The current boundary keeps `CoreEval` pure and puts filesystem effects in
`HostEval.lean`. Path values are just data in the pure evaluator; only the host
import layer interprets relative path text as filesystem input.

The smoke corpus has parser coverage for `import ./foo.nix`, pure eval-fail
coverage for an import attempt, pure eval coverage for path values, and
`e2e/import-manifest.txt` coverage for the explicit host IO path, including
the imported-function rejection boundary.
