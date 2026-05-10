# Architecture

## Overview

The project is split into two layers with a clean boundary between them.

```
┌─────────────────────────────┐
│  Lean 4  (NixParserLean)    │
│                             │
│  Syntax.lean   — AST types  │
│  Parser.lean   — parser     │
│  Validate.lean — validator  │
│  Main.lean     — CLI        │
└────────────┬────────────────┘
             │ subprocess (stdin/stdout/exit code)
┌────────────▼────────────────┐
│  Rust  (e2e/runner)         │
│                             │
│  reads manifest.txt         │
│  runs parser per fixture    │
│  classifies outcomes        │
│  prints summary             │
└─────────────────────────────┘
```

**Lean** owns the language model: the AST definition, all parsing logic, and all semantic validation. It is the authoritative source of what is and is not accepted Nix syntax.

**Rust** owns corpus orchestration: reading the manifest, invoking the parser as a subprocess per fixture file, classifying outcomes (pass / parse-fail / validation-fail), and summarizing results. It does not parse Nix itself.

The boundary is a process invocation. The Rust runner shells out to `lake exe nixparserlean --file <path>` and inspects the exit code and the first line of stderr to classify the result.

## Data flow

```
manifest.txt
    │
    │ parse_manifest()
    ▼
Vec<Case>  (path, expectation, note)
    │
    │ for each case: run_parser()
    ▼
Outcome  (Pass | ParseFail | ValidationFail | OtherFail)
    │
    │ compare with Expectation
    ▼
Summary  (passed / expected failures / unexpected failures)
    │
    ▼
stdout summary line + stderr for surprises
```

## Lean pipeline

Inside the Lean executable, the pipeline is:

```
String input
    │
    │ NixParserLean.parse
    ▼
Except String Expr
    │
    │ NixParserLean.validate
    ▼
Except String Unit
    │
    │ IO.println (repr expr)  on success
    │ IO.eprintln err         on failure
    ▼
exit 0 / exit 1
```

`parse` and `validate` are pure functions. All IO lives in `Main.lean`.

## Error classification

The Rust runner uses the first line of stderr to distinguish error kinds:

| Prefix | Classification |
|---|---|
| `parse error at offset N:` | `ParseFail` |
| `semantic error:` | `ValidationFail` |
| anything else | `OtherFail` |

This convention is established in `Parser.lean` (`failAt`) and `Validate.lean` (`bindingConflictMessage`).

## Nix flake

`flake.nix` provides:

- `devShells.default` — shell with `lean4`, `cargo`, `rustc`, `curl`, `git`.
- `checks.e2e-smoke` — runs `lake build` then the full e2e runner; used for CI.
- `formatter` — `nixpkgs-fmt`.

Supported systems: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
