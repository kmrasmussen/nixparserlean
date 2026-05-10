# Next audacious step

The parser now covers a much larger slice of everyday Nix syntax, and the Rust
harness has the beginning of external corpus support.

The next ambitious move should turn that support into reproducible pressure:

1. Add optional hashes to `url` manifest entries.
2. Verify cached files before running them.
3. Add the first tiny pinned external corpus manifest that is safe to run in CI
   as expected failures.
4. Start recording recurring failures by syntax category.

After that, the parser should grow source positions. The current offset-only
errors are enough for smoke tests, but external files need line and column
diagnostics if failures are going to guide development efficiently.

That sequence keeps the project honest. Corpus inputs create pressure from real
Nix. Hashes keep that pressure reproducible. Source positions make the pressure
actionable.
