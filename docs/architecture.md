# Architecture

## Overview

The project is split into two layers with a clean boundary between them.

```
┌──────────────────────────────────────┐
│  Lean 4  (NixParserLean)             │
│                                      │
│  Syntax.lean        — surface AST    │
│  Parser/Basic.lean  — parser state,  │
│                       token/ident/   │
│                       int/path/ws    │
│  Parser.lean        — expression     │
│                       grammar        │
│  Validate.lean      — surface        │
│                       validator      │
│  Core.lean          — core AST       │
│  Desugar.lean       — surface→core   │
│  CoreValidate.lean  — core invariants│
│  CoreEval.lean      — evaluator      │
│  HostEval.lean      — host imports   │
│  Main.lean          — CLI            │
└────────────┬─────────────────────────┘
             │ subprocess (stdin/stdout/exit code)
┌────────────▼─────────────────────────┐
│  Rust  (e2e/runner)                  │
│                                      │
│  reads manifest.txt                  │
│  runs parser per fixture             │
│  classifies outcomes                 │
│  prints summary                      │
└──────────────────────────────────────┘
```

**Lean** owns the language model: the surface AST, all parsing logic,
semantic validation, surface-to-core desugaring, core invariant checking, the
first pure evaluator, and the explicit host IO wrapper for relative imports.
It is the authoritative source of what is and is not accepted Nix syntax, and
of how the supported subset evaluates.

`Parser.lean` is split into two files: `Parser/Basic.lean` carries the
reusable lexer-level infrastructure (parser state, whitespace, identifiers,
integers, path literals, keyword/token primitives), while `Parser.lean`
itself carries the recursive-descent expression/binding grammar that builds
on those primitives.

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
Outcome  (Pass | ParseFail | ValidationFail | CoreFail | EvalFail | OtherFail)
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
Except ParseError Expr
    │
    │ NixParserLean.validate
    ▼
Except String Unit
    │
    │ optionally NixParserLean.desugar
    ▼
Except String Core.Expr
    │
    │ NixParserLean.Core.validate
    ▼
Except String Unit
    │
    │ optionally NixParserLean.HostEval.resolveImports for --eval-imports
    ▼
Except String Core.Expr
    │
    │ optionally NixParserLean.Core.eval
    ▼
Except String Core.Eval.Value
    │
    │ IO.println (repr expr/coreExpr/value)  on success
    │ IO.eprintln err         on failure
    ▼
exit 0 / exit 1
```

`parse`, `validate`, `desugar`, core validation, and core evaluation are pure
functions. `HostEval.lean` is the explicit exception: it performs filesystem IO
for `--eval-imports`, then hands a core expression back to the pure evaluator.
CLI orchestration lives in `Main.lean`.

## Error classification

The Rust runner uses the first line of stderr to distinguish error kinds:

| Prefix | Classification |
|---|---|
| `parse error at offset N:` | `ParseFail` |
| `semantic error:` | `ValidationFail` |
| `core error:` | `CoreFail` |
| `eval error:` | `EvalFail` |
| anything else | `OtherFail` |

This convention is established in `Parser/Basic.lean` (`failAt`),
`Validate.lean` (`bindingConflictMessage`), `CoreValidate.lean`, and
`CoreEval.lean` and `HostEval.lean` (`eval error:` messages from evaluation
and import IO).

Core validation deliberately keeps the `core error:` prefix separate from
surface `semantic error:` diagnostics. The e2e runner exposes that distinction
as the `core-fail` manifest expectation.

## Nix flake

`flake.nix` provides:

- `devShells.default` — shell with `lean4`, `cargo`, `rustc`, `curl`, `git`.
- `checks.e2e-smoke` — runs `lake build` then the full e2e runner; used for CI.
- `formatter` — `nixpkgs-fmt`.

Supported systems: `x86_64-linux`, `aarch64-linux`, `x86_64-darwin`, `aarch64-darwin`.
