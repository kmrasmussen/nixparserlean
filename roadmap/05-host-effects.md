# Host Effects Roadmap

Host effects are the boundary where Nix stops being just a pure expression
language. This project should keep that boundary explicit so pure semantics,
analysis artifacts, and proof targets do not depend on the user's filesystem by
accident.

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
- can apply immediately imported closures when the argument and result are
  representable;
- rejects bare imported closures;
- rejects angle, home, absolute, store, network, and search-path imports.

## Principle

Never make `CoreEval` perform host IO. Host-backed behavior belongs in
`HostEval.lean` or a future explicitly named effect layer.

Host-effect work should also produce inspectable artifacts where practical:
which import was read, which search-path entry resolved it, which normalized
key was used for cycle detection, and which behavior remains deliberately
unsupported.

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

Option 1 is complete: the imported-function diagnostic is stable and tested.
The first option-3 slice is also landed for immediate imported-closure
application, without moving filesystem IO into `CoreEval`.

Current design note: `docs/host-effect-evaluator-shape.md` chooses a
host-aware import substitution layer as the next direction. The compatibility
path keeps reifying simple imported values, while the new host layer gets an
internal value slot for imported closures. `CoreEval` remains filesystem-free.

Next widening criteria:

- Imported function applications can use arguments from the importing
  expression's local environment.
- Imported functions that return functions have a policy.
- Representable imported values still use the existing reification path.
- `CoreEval.lean` remains filesystem-free.

## Milestone B: Relative Path Normalization

Current behavior joins base directory and relative import path text, then
normalizes `.` and `..` path segments lexically before file reads and recursion
detection. It does not resolve symlinks or canonical filesystem identity.

Landed policy:

- Host imports use the same lexical normalized path for file reads and
  recursion detection.
- Keep pure path values unnormalized.
- `./nested/../file.nix` style aliases are covered in the import manifest.
- Alias-based recursive imports are expected eval failures with the normalized
  recursion key.

Acceptance criteria:

- Recursive import detection is robust for simple `./a/../x.nix` aliases.
- No pure `Value.path` behavior changes.

## Milestone C: Search Path And Angle Imports

Angle paths like `<nixpkgs>` are currently parsed as path values and rejected
as imports.

Search paths now have a deterministic design note. Do not implement them until:

- the host effect API has a configurable search path environment;
- tests can run without relying on the user's machine;
- docs explain that this is host-backed behavior, not pure evaluation.

First acceptable implementation:

- CLI flag or environment argument that supplies a search path mapping;
- e2e fixture using a temp or repo-local search root;
- no default dependency on system `<nixpkgs>`.

The proposed shape is documented in
`docs/angle-search-path-design.md`: use explicit `--search-path NAME=PATH`
entries, keep `CoreEval` pure, and preserve the current angle-import rejection
when no mapping is supplied.

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
