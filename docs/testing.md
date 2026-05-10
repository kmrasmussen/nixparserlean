# Testing

## Layers

### Smoke corpus (committed fixtures)

Small, self-contained `.nix` files live under `e2e/corpus/smoke/`. Each fixture exercises one specific construct or failure mode. They are committed to the repository and reviewed alongside parser changes.

Current smoke fixtures:

| File | Expected outcome | What it tests |
|---|---|---|
| `attrset.nix` | pass | basic attribute set with inline and block comments |
| `let-list.nix` | pass | `let ... in` with a list body |
| `lambda.nix` | pass | attribute-set lambda parameter (`{ pkgs }: ...`) |
| `identity-lambda.nix` | pass | single-identifier lambda parameter |
| `open-param-lambda.nix` | pass | `{ a, ... }:` ellipsis parameter |
| `default-param-lambda.nix` | pass | attrset lambda parameter default |
| `aliased-param-lambda.nix` | pass | `args@{ ... }` parameter alias |
| `reverse-aliased-param-lambda.nix` | pass | `{ ... }@args` parameter alias |
| `aliased-default-param-lambda.nix` | pass | parameter alias with defaulted entry |
| `if-then-else.nix` | pass | conditional expression |
| `assert.nix` | pass | `assert condition; body` |
| `select.nix` | pass | attribute selection (`a.b.c`) |
| `select-default.nix` | pass | attribute selection with `or` default |
| `has-attr.nix` | pass | attribute existence test |
| `application.nix` | pass | function application |
| `let-application.nix` | pass | let-bound lambda applied to an argument |
| `parenthesized.nix` | pass | parenthesized sub-expression |
| `quoted-attr-names.nix` | pass | quoted static attribute names in binding/select/hasAttr |
| `relative-path.nix` | pass | relative path literal |
| `angle-path.nix` | pass | `<nixpkgs>`-style path |
| `import-path.nix` | pass | `import ./foo.nix` pattern |
| `inherit-from.nix` | pass | `inherit (scope) name;` form |
| `with-expr.nix` | pass | `with pkgs; ...` |
| `addition.nix` | pass | `+` binary operator |
| `arithmetic-operators.nix` | pass | `-`, `*`, and `/` binary operators |
| `update-operator.nix` | pass | `//` attribute-set update |
| `boolean-operators.nix` | pass | `&&`, `\|\|`, `==` |
| `operator-table.nix` | pass | comparisons, implication, concat, and unary operators |
| `string-interpolation.nix` | pass | quoted string interpolation |
| `indented-string.nix` | pass | indented string interpolation |
| `attrpath-siblings.nix` | pass | two sibling dotted-path bindings |
| `duplicate-attr.nix` | validation-fail | duplicate key in attribute set |
| `duplicate-inherit.nix` | validation-fail | duplicate name in `inherit` |
| `duplicate-let.nix` | validation-fail | duplicate binding in `let` |
| `duplicate-param-lambda.nix` | validation-fail | duplicate destructured lambda parameter |
| `prefix-attr-conflict.nix` | validation-fail | `a.b = 1; a = 2;` prefix conflict |
| `reverse-prefix-attr-conflict.nix` | validation-fail | same conflict, reversed order |
| `missing-equals.nix` | parse-fail | binding without `=` |

### Manifest format

`e2e/manifest.txt` lists every fixture. Each non-comment line has three tab-separated fields:

```
<path>  <expectation>  <note>
```

- `path` — relative to the repository root.
- `expectation` — one of `pass`, `parse-fail`, `validation-fail`.
- `note` — free-text description shown in failure output.

Lines starting with `#` and blank lines are ignored.

### e2e runner

The Rust program at `e2e/runner/src/main.rs` reads the manifest and runs the parser once per case.

**Invocation:**
```sh
cargo run --manifest-path e2e/runner/Cargo.toml -- \
    --manifest e2e/manifest.txt \
    [--parser "lake exe nixparserlean --file"]
```

**Classification:** The runner inspects the parser's exit code and the first line of stderr:

| First line of stderr | Classified as |
|---|---|
| starts with `parse error` | `ParseFail` |
| starts with `semantic error` | `ValidationFail` |
| exit 0 | `Pass` |
| anything else | `OtherFail` |

**Outcome:**
- Expected match → counted as passed or expected failure.
- Unexpected failure or unexpected success → printed to stderr and exits 1.

**Summary line (stdout):**
```
e2e: N passed, N expected parse failures, N expected validation failures,
     N unexpected failures, N unexpected successes
```

## Adding a new fixture

1. Create a `.nix` file under `e2e/corpus/smoke/`.
2. Add a line to `e2e/manifest.txt` with the correct expectation.
3. Run the e2e runner to confirm the outcome matches.

## Validation pass

Semantic validation (`NixParserLean/Validate.lean`) runs after parsing and checks for:

- **Duplicate bindings** — two `assign` bindings with the same attribute path.
- **Prefix conflicts** — one attribute path is a prefix of another (e.g. `a.b = 1; a = 2;`).
- Both forms of `inherit` contribute their names as single-part attribute paths for conflict checking.

Validation errors are formatted as:
```
semantic error: <description>
```

## CI

`flake.nix` defines a `checks.e2e-smoke` derivation that runs `lake build` followed by the full e2e runner. This check runs on all four supported systems via `nix flake check`.
