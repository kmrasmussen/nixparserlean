# Host Effects Roadmap

Host effects are the boundary where Nix stops being just a pure expression
language. This project should keep that boundary explicit.

## Current Boundary

Pure evaluation:

- evaluates path literals as inert text values;
- does not touch the filesystem;
- rejects `import` with `eval error: unsupported import evaluation`.

Host evaluation through `--eval-imports`:

- supports relative `./...` and `../...` imports;
- reads files with `IO.FS.readFile`;
- parses, validates, desugars, core-validates, evaluates, and reifies
  representable imported values;
- rejects imported closures;
- rejects angle, home, absolute, store, network, and search-path imports.

## Principle

Never make `CoreEval` perform host IO. Host-backed behavior belongs in
`HostEval.lean` or a future explicitly named effect layer.

## Milestone A: Better Imported Function Policy

Problem:

Imported files can evaluate to closures, but closures cannot be reified into
core syntax for the final pure pass.

Options:

1. Keep rejecting imported functions, but improve diagnostics and docs.
2. Reify closures with a core value expression form.
3. Change `--eval-imports` so imports are evaluated directly in a host-aware
   evaluator rather than reified into core.

Recommendation:

Start with option 1. Add fixtures that prove the diagnostic is stable. Then
design option 3 if real module patterns require it.

Acceptance criteria:

- Fixture for importing a function-valued file.
- Error is classified as `eval-fail`.
- Docs state why closure reification is not available yet.

## Milestone B: Relative Path Normalization

Current behavior joins base directory and relative import path text. It does
not normalize `..`, symlinks, or canonical paths.

Next step:

- Decide whether host imports normalize only for recursion detection, only for
  file reads, or not at all.
- Keep pure path values unnormalized.

Acceptance criteria:

- Recursive import detection is robust for simple `./a/../x.nix` aliases, or
  the limitation is documented and tested.
- No pure `Value.path` behavior changes.

## Milestone C: Search Path And Angle Imports

Angle paths like `<nixpkgs>` are currently parsed as path values and rejected
as imports.

Do not implement search paths until:

- the host effect API has a configurable search path environment;
- tests can run without relying on the user's machine;
- docs explain that this is host-backed behavior, not pure evaluation.

First acceptable implementation:

- CLI flag or environment argument that supplies a search path mapping;
- e2e fixture using a temp or repo-local search root;
- no default dependency on system `<nixpkgs>`.

## Milestone D: Store Paths And Realization

Store paths should remain inert until the project has a store model. Copying
paths to the store, derivation outputs, string contexts, and realization are
out of scope for the near term.

Useful near-term work:

- classify store-like paths as path values;
- document that they are not checked or realized;
- keep interpolation of paths unsupported until string context policy exists.

## Milestone E: Effect-Typed Core

Long-term possibility:

- pure core evaluator;
- host/effect evaluator;
- explicit effect type or capability record for imports/path lookups.

This is not a near-term implementation target. It becomes relevant after
imported functions or search path behavior are needed.
