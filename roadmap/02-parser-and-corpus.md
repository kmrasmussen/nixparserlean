# Parser And Corpus Roadmap

The parser is broad enough that future parser work should be driven by the
pinned external corpus rather than by isolated feature guesses.

## Current Parser Shape

The parser is handwritten recursive descent. This is still the right local
style because the grammar is explicit and easy to audit. The cost is
termination debt: most parser functions are still `partial`.

Supported surface areas include lambdas, attrsets, `let`, control flow,
strings, interpolation, dynamic attrs, paths, imports as application, selection
forms, and the main operator table.

## External Corpus State

The pinned external manifest is already useful:

- 15 passing pinned nixpkgs files.
- 0 expected parse failures in the current pinned set.

The first blocker set has been ratcheted to green. The next parser/corpus
step is infrastructure for growing the pinned set without making network-backed
runs part of the ordinary flake check.

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

After the four current blockers, grow corpus infrastructure deliberately:

- Add content hashes to URL rows.
- Add a summary command or script for blocker counts.
- Add a non-blocking "refresh external corpus" workflow.
- Consider splitting external manifests into parser, desugar, and eval lanes.

Do not make network-backed corpus runs required for ordinary flake checks.
