# Parser And Corpus Roadmap

Parser work is the credibility layer for the whole project. NixParserLean can
only be a useful semantic lens if it stays attached to real Nix files, preserves
source positions, and turns corpus failures into clear semantic categories.

Future parser work should therefore be driven by pinned corpus rows,
representative fixtures, and diagnostic contracts rather than by isolated
feature guesses.

## Current Parser Shape

The parser is handwritten recursive descent. This is still the right local
style because the grammar is explicit and easy to audit. The cost is
termination debt: most parser functions are still `partial`.

Supported surface areas include lambdas, attrsets, `let`, control flow,
strings, interpolation, dynamic attrs, paths, imports as application, selection
forms, and the main operator table.

## External Corpus State

The pinned external manifest is already useful:

- 23 passing pinned nixpkgs files.
- 0 expected parse failures in the current pinned set.

The first blocker set has been ratcheted to green, and the second pinned corpus
wave also passed without new blocker categories. The next parser/corpus step is
either a third pinned wave from a different nixpkgs area or infrastructure for
non-blocking external refresh reporting. Network-backed corpus runs should
remain outside the ordinary flake check.

## Milestone A: Spaced Dynamic Selection (complete)

Problem:

Real nixpkgs code can split a selection across whitespace/newlines before a
dynamic selector:

```nix
expr
.${name}
```

Current risk:

- `parseSelect` intentionally made `.` adjacency strict to avoid misreading
  `import ./default.nix` as selection off `import`.
- Any fix must preserve the import/path disambiguation.

Plan:

1. Add smoke fixtures for newline-before-dot dynamic selection and for
   `import ./file.nix`.
2. Adjust selection parsing only where the next token is a valid selector, not
   a path literal argument.
3. Keep the application parser from treating whitespace-separated path args as
   selection.
4. Update the two external manifest rows if they advance.

Acceptance criteria:

- Both `spaced-dynamic-selection` external rows pass or move to a later
  blocker.
- Existing import path fixtures still pass.
- The parser docs explain the selection/path ambiguity.

## Milestone B: Quoted Inherit Names (complete)

Problem:

nixpkgs has scoped inherit names like:

```nix
inherit (scope) "or";
```

Current parser behavior:

- `parseInheritNames` consumes identifiers, not quoted attr names.
- Attribute path parsing already has quoted-name logic.

Plan:

1. Reuse or factor attr-name parsing for inherit names.
2. Preserve validation semantics: inherited quoted static names should count
   as binding names.
3. Decide whether dynamic quoted inherit names are supported or rejected. Real
   Nix inherit names should be statically resolvable for this slice.

Acceptance criteria:

- Smoke fixture for quoted inherit names.
- External `quoted-inherit-name` row moves to pass or a narrower blocker.
- Duplicate inherit validation still catches quoted/static duplicates.

## Milestone C: Dot-File Path Argument (complete)

Problem:

The external blocker `path-argument-dot-file` stops at code like:

```nix
fileContents ./.version
```

Current parser behavior:

- Path starts include `./`.
- Application parsing has already had selection/path ambiguity issues.

Plan:

1. Add an application fixture with a dot-file relative path argument.
2. Identify whether the current blocker is lexing, app stop logic, or a
   surrounding construct in the external file.
3. Fix the narrow cause without weakening operator disambiguation.

Acceptance criteria:

- `fileContents ./.version` parses as application to a path literal.
- Existing `parenthesized-import-application` and import fixtures still pass.
- External row advances.

## Milestone D: Indented String Escapes (complete)

Problem:

The external blocker `indented-string-escape` stops at literal content around:

```nix
''${path}
```

Current parser behavior:

- Indented strings support interpolation but not the full Nix escape rules for
  literal `${` and related forms.

Plan:

1. Write a small string-fixture matrix for indented string escapes.
2. Define the subset of Nix escape behavior to support first.
3. Add parser tests and update docs.

Acceptance criteria:

- The specific external blocker advances.
- The string parser docs state which quoted and indented escapes are modeled.
- String interpolation fixtures still validate/evaluate as before.

## Milestone E: External Corpus Infrastructure

The next corpus work should make blocker classification more useful:

- split or report external rows by parser, validation, desugar, core
  validation, evaluation, and host-effect lane;
- enforce immutable pinning or hashes for URL rows;
- keep `./e2e/external-summary.sh` as the quick blocker summary;
- add a non-blocking "refresh external corpus" workflow only if it does not
  enter ordinary local gates.

Do not make network-backed corpus runs required for ordinary flake checks.

## Milestone F: Second Pinned Corpus Wave (complete)

The second real coverage step added another batch of pinned nixpkgs files as
its own ticket, not as incidental parser feature churn.

Completed shape:

1. Added eight immutable nixpkgs URLs from areas not covered by the first 15
   rows.
2. Kept every new row as `pass` only after running the external manifest.
3. Used `./e2e/external-summary.sh`; it reports 23 cases, 23 passes, and no
   expected non-pass blockers.
4. Created no follow-up blocker tickets because this wave introduced no
   blocker categories.

Acceptance criteria:

- The external manifest remains deterministic and pinned to immutable upstream
  revisions.
- Any non-pass rows have notes specific enough to become tickets.
- Ordinary `nix flake check` remains network-free.
