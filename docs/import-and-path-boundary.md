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
  importing file's directory, lexically normalizes `.` and `..` path segments,
  reads the target file, parses/validates/desugars it, evaluates it in
  isolation, and reifies representable values, including path values, before
  the final pure evaluation pass.
- Immediately applied imported functions, such as
  `import ./function.nix 41`, can run in the host import layer when the
  argument and result are representable values.
- Bare imported functions are still rejected with
  `eval error: unsupported imported function values`, because closures cannot
  currently be reified back into core syntax for the final pure pass.
- `--eval-imports` still rejects absolute, home-relative, and angle imports.
  The future angle-import design is documented in
  [angle-search-path-design.md](angle-search-path-design.md).

This is deliberate. Import needs host filesystem IO, path normalization, base
directory policy, and a decision about how much Nix path behavior to model.
The current boundary keeps `CoreEval` pure and puts filesystem effects in
`HostEval.lean`. Path values are just data in the pure evaluator; only the host
import layer interprets relative path text as filesystem input.

Relative import paths are joined with the importing file's directory and
normalized lexically before file reads and before insertion into the import
recursion stack. This handles simple aliases such as `./nested/../file.nix`
without depending on filesystem canonicalization. Symlinks are not resolved,
and the policy does not call `realpath`; it is a text normalization for the
explicit host import lane only. Pure path values remain unnormalized text.

The smoke corpus has parser coverage for `import ./foo.nix`, pure eval-fail
coverage for an import attempt, pure eval coverage for path values, and
`e2e/import-manifest.txt` coverage for the explicit host IO path, including
relative alias normalization, recursive alias detection, imported-function
application, and bare-function rejection boundaries.
