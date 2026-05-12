# Testing

## Layers

The project has one default smoke manifest plus focused end-to-end manifests,
each driven by the same Rust runner with a different `--parser` command line:

| Manifest | Parser command | Purpose |
|---|---|---|
| `e2e/manifest.txt` | `lake exe nixparserlean --file` | parser + surface validator |
| `e2e/core-validation-manifest.txt` | `lake exe nixparserlean --core-validation-smoke --file` | runner classification for core validation failures |
| `e2e/desugar-manifest.txt` | `lake exe nixparserlean --desugar --file` | parser + surface validator + desugar + core validator |
| `e2e/eval-manifest.txt` | `lake exe nixparserlean --eval --file` | the full pipeline including the evaluator |
| `e2e/import-manifest.txt` | `lake exe nixparserlean --eval-imports --file` | explicit host IO path for relative imports |
| `e2e/fuel-manifest.txt` | `lake exe nixparserlean --eval --fuel 0 --file` | fuel exhaustion at entry |
| `e2e/fuel-low-manifest.txt` | `lake exe nixparserlean --eval --fuel 1 --file` | deterministic low-fuel failure |
| `e2e/fuel-success-manifest.txt` | `lake exe nixparserlean --eval --fuel 2 --file` | sufficient-fuel success |
| `e2e/fuel-high-manifest.txt` | `lake exe nixparserlean --eval --fuel 5 --file` | extra-fuel success for the primitive binary smoke |
| `e2e/json-manifest.txt` | `lake exe nixparserlean --format json --file` and desugar/eval JSON variants | JSON output contract |

All manifests use the same row format. The `flake.nix` `checks.e2e-smoke`
derivation runs these manifests, JSON in surface/desugar/eval modes, and CLI
help/unknown-flag checks.

### Smoke corpus

Small, self-contained `.nix` files live under `e2e/corpus/smoke/`. Each
fixture exercises one specific construct or failure mode. They are committed
to the repository and reviewed alongside parser/evaluator changes.

Smoke fixtures are grouped roughly into:

- **Surface forms (parser smoke):** `attrset.nix`, `let-list.nix`,
  `lambda.nix`, `identity-lambda.nix`, `open-param-lambda.nix`,
  `default-param-lambda.nix`, `aliased-param-lambda.nix`,
  `reverse-aliased-param-lambda.nix`, `aliased-default-param-lambda.nix`,
  `if-then-else.nix`, `assert.nix`, `select.nix`, `select-default.nix`,
  `has-attr.nix`, `application.nix`, `let-application.nix`,
  `parenthesized.nix`, `quoted-attr-names.nix`, `relative-path.nix`,
  `angle-path.nix`, `import-path.nix`, `inherit-from.nix`, `with-expr.nix`,
  `addition.nix`, `arithmetic-operators.nix`, `update-operator.nix`,
  `boolean-operators.nix`, `operator-table.nix`, `string-interpolation.nix`,
  `indented-string.nix`, `attrpath-siblings.nix`, `dynamic-attr-names.nix`,
  `spaced-dynamic-selection.nix`, and `dot-file-path-argument.nix`.
- **Surface validation failures:** `duplicate-attr.nix`,
  `duplicate-inherit.nix`, `duplicate-let.nix`,
  `duplicate-param-lambda.nix`, `prefix-attr-conflict.nix`,
  `reverse-prefix-attr-conflict.nix`.
- **Surface parse failures:** `missing-equals.nix`.
- **Eval pass cases (`eval-*.nix`):** integer arithmetic, lambda application
  forms, lexical closures, recursive `let` and `rec { ... }`, with-scope
  fallback and lexical shadowing, dynamic attribute binding/selection,
  spaced dynamic selection, quoted dynamic attribute names, string
  interpolation/coercion, floats and paths as values, path equality,
  list concatenation, shallow attrset update, numeric comparisons,
  attribute-set lambda parameters with defaults / overrides / ellipsis /
  aliases.
- **Host import cases (`eval-host-*.nix`):** relative import success through
  `--eval-imports`, plus unsupported import/path cases that must remain
  classified as eval failures.
- **Eval failure cases (`eval-*-fail` style):**
  `eval-paramset-missing.nix`, `eval-paramset-extra.nix`,
  `eval-paramset-default-later.nix`, `eval-let-recursive-self.nix`,
  `eval-rec-attrset-self.nix`, `eval-rec-attrset-mutual.nix`,
  `eval-with-non-attr.nix`,
  `eval-dynamic-attr-interpolation-type.nix`,
  `eval-equality-cross-kind.nix`, `eval-inequality-cross-kind.nix`,
  `eval-string-interpolation-float.nix`,
  `eval-string-interpolation-attrset.nix`,
  `eval-let-dynamic-binding.nix`, duplicate dynamic attribute fixtures,
  list-concat/attrset-update type fixtures, and float division by zero. These
  exercise paths that the surface parser/validator accept but the evaluator
  deliberately rejects.

Examples under `examples/` are also referenced from e2e manifests so they are
both documentation and regression tests. The focused suite covers pure
expressions, recursion, lambdas, dynamic attributes, host imports, and a
proof-oriented static attrset fragment; `current-core-showcase/` remains as the
combined integration example.

### Manifest format

Manifest rows are tab-separated and accept three forms:

```
<path>                 <expectation>  <note>
file <path>            <expectation>  <note>
url  <cache-name> <url>  <expectation>  <note>
```

- `path` — relative to the repository root.
- `expectation` — one of `pass`, `parse-fail`, `validation-fail`,
  `core-fail`, `eval-fail`.
- `note` — free-text description shown in failure output.
- `url` rows download the URL into `--cache-dir` (default `e2e/cache`) using
  `curl`, and then run the parser on the cached file.

Lines starting with `#` and blank lines are ignored. See
`e2e/external-manifest.example.txt` for an annotated example of the
file/url forms.

### External corpus

`e2e/external-manifest.txt` is a curated, pinned nixpkgs corpus. It is not
part of the default flake check because the first run may need network access,
but it should be run whenever parser coverage changes:

```sh
cargo run --manifest-path e2e/runner/Cargo.toml -- \
    --manifest e2e/external-manifest.txt
```

The runner caches downloaded files under `e2e/cache`, so later runs are local
unless a new URL row is added or the cache is cleared.

Expected external failures should start their note with a stable blocker
category:

```text
blocker: category-name; short description of the first failing construct
```

To summarize current expected external blockers:

```sh
e2e/external-summary.sh e2e/external-manifest.txt
```

When a parser or evaluator change makes an expected external failure pass, keep
the file in the manifest and change its expectation to `pass`. When a failure
moves to a later construct, update the blocker category and note before
committing the change.

External URL rows should be pinned to immutable upstream revisions. Optional
content hashes are recorded as comment rows immediately before the URL row:

```text
# sha256<TAB>cache-name<TAB>hex-encoded-sha256
url<TAB>cache-name<TAB>url<TAB>expectation<TAB>note
```

The runner ignores comment rows, so this provenance format remains compatible
with existing manifest behavior. The policy is documentation-first for now;
hash enforcement can be added later without changing URL row parsing.

### e2e runner

The Rust program at `e2e/runner/src/main.rs` reads a manifest and runs the
parser once per case.

**Invocation:**
```sh
cargo run --manifest-path e2e/runner/Cargo.toml -- \
    --manifest e2e/manifest.txt \
    [--parser "lake exe nixparserlean --file"] \
    [--cache-dir e2e/cache]
```

**Classification:** the runner inspects the parser's exit code and the first
line of stderr:

| First line of stderr | Classified as |
|---|---|
| starts with `parse error` | `ParseFail` |
| starts with `semantic error` | `ValidationFail` |
| starts with `core error` | `CoreFail` |
| starts with `eval error` | `EvalFail` |
| exit 0 | `Pass` |
| anything else | `OtherFail` |

**Outcome:**
- Expected match → counted as `passed` or `expected_*_failures`.
- Unexpected failure or unexpected success → printed to stderr and the
  runner exits 1.

**Summary line (stdout):**
```
e2e: N passed, N expected parse failures, N expected validation failures,
     N expected core failures, N expected eval failures,
     N unexpected failures, N unexpected successes
```

## Adding a new fixture

1. Create a `.nix` file under `e2e/corpus/smoke/`.
2. Add a row to the appropriate manifest with the correct expectation.
3. If it covers an evaluator behavior, also exercise it with `--eval` or
   `--eval-imports`, as appropriate.
4. Run the e2e runner to confirm the outcome matches.

## Surface validation pass

Semantic validation (`NixParserLean/Validate.lean`) runs after parsing and
checks for:

- **Duplicate bindings** — two `assign` bindings with the same attribute path.
- **Prefix conflicts** — one attribute path is a prefix of another
  (e.g. `a.b = 1; a = 2;`).
- **Duplicate `inherit` names** — `inherit` and `inherit (scope)` contribute
  their names as single-part attribute paths for conflict checking.
- **Duplicate destructured lambda parameters** — `{ a, a }: ...` is rejected.
- **Recursive validation** of expressions inside string interpolations and
  dynamic attribute path segments.

Validation errors are formatted as:
```
semantic error: <description>
```

## Core validation pass

`NixParserLean/CoreValidate.lean` runs after desugaring and is invoked by
`Main.lean` whenever `--desugar` or `--eval` is requested. See
[core.md](core.md) for the invariants it checks. Core-validation errors are
prefixed with `core error:` and match the runner's `core-fail` expectation.
`e2e/core-validation-manifest.txt` exercises this contract with a small CLI
smoke mode that constructs an invalid core expression directly.

## CI

`flake.nix` defines a `checks.e2e-smoke` derivation that runs `lake build`,
the parser/validator e2e runner, the core-validation contract manifest, the
focused desugar manifest, the eval manifest, the host import manifest, the
fuel manifests, JSON output checks, CLI help text checks, and the unknown-flag
diagnostic check. This check runs on all supported systems via
`nix flake check`.
