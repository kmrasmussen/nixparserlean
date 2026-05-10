# CLI

`lake exe nixparserlean` accepts Nix source either from `--file PATH` or from
the remaining non-flag arguments joined with spaces. With no source argument it
uses a small built-in example.

## Flags

- `--file PATH` reads input from a file.
- `--desugar` prints the validated core AST instead of the surface AST.
- `--eval` evaluates the validated core AST.
- `--fuel N` sets evaluator thunk-forcing fuel for `--eval`.
- `--format repr|json` selects output format. The default is `repr`.
- `--help` prints usage.

Unknown flags fail with a non-zero exit code and `unknown flag: <flag>`.

## JSON Format

JSON output is selected with `--format json`.

Surface and core expressions use objects with a `kind` field. Constructor fields
are encoded by name. For example:

```json
{"kind":"int","value":42}
```

Core evaluation values also use a `kind` field:

```json
{"kind":"int","value":49}
```

The schema is intentionally small and mirrors the current AST constructors:
`int`, `float`, `str`, `bool`, `null`, `ident`, `path`, `list`, `attrset`,
`letIn`, `lambda`, `ifThenElse`, `assert`, `with`, `select`, `hasAttr`, `app`,
`unary`, and `binary`. Core bindings use `staticAssign`, `inheritAssign`, and
`dynamicAssign`.

The default `repr` output remains for human debugging and backwards
compatibility, but tools should prefer JSON.
