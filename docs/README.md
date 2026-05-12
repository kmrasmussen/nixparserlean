# NixParserLean Documentation

NixParserLean is a Nix language parser, semantic model, and small evaluator
written in Lean 4. The project aims to build a formally-grounded representation
of Nix expressions, with a separate Rust harness for end-to-end corpus testing.

## Goals

- Model Nix syntax and semantics faithfully in Lean 4's type system.
- Build a handwritten, readable parser that makes the underlying grammar visible.
- Detect semantic errors (duplicate bindings, conflicting attribute paths) at validation time.
- Lower surface syntax into a smaller `Core` language that is easier to reason about and to evaluate.
- Drive parser, validator, desugarer, and evaluator coverage with a growing corpus of real-world Nix files.

## Non-goals (current)

- Source-preserving or round-tripping output (comments are discarded as whitespace).
- Complete Nix language support in a single pass — coverage grows incrementally.
- Proof of semantic properties — the model is a prerequisite, not the finished product.
- Complete path semantics, derivations, store interaction, and network fetchers.

## Documents

| File | Contents |
|---|---|
| [architecture.md](architecture.md) | Component layout and data flow |
| [ast.md](ast.md) | Surface AST node reference |
| [parser.md](parser.md) | Parser internals and operator precedence |
| [core.md](core.md) | Core AST, desugaring, core validation, and evaluator |
| [testing.md](testing.md) | Testing strategy, manifest formats, and e2e runner |
| [angle-search-path-design.md](angle-search-path-design.md) | Deterministic design for future `<name>` host imports |
| [host-effect-evaluator-shape.md](host-effect-evaluator-shape.md) | Chosen next shape for host-aware import evaluation |
| [parser-expression-termination-strategy.md](parser-expression-termination-strategy.md) | Fuel-first plan for removing expression parser `partial` debt |
| [scaling-plan.md](scaling-plan.md) | Roadmap for growing the parser and corpus |
| [design-notes.md](design-notes.md) | Implementation tradeoffs and the "why" behind specific choices |
| [../roadmap/](../roadmap/) | Active long-horizon plans that span multiple tickets |

## Quick start

```sh
# Build the Lean parser
lake build

# Parse a file
lake exe nixparserlean --file path/to/file.nix

# Print the desugared core AST
lake exe nixparserlean --desugar --file path/to/file.nix

# Evaluate the supported core fragment
lake exe nixparserlean --eval --file path/to/file.nix

# Evaluate with the explicit host IO layer for relative imports
lake exe nixparserlean --eval-imports --file path/to/file.nix

# Parse an inline expression (any args that aren't recognised flags)
lake exe nixparserlean '{ x = 1; }'

# Run the e2e smoke corpus
cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/manifest.txt

# Run the desugar manifest
cargo run --manifest-path e2e/runner/Cargo.toml -- \
    --manifest e2e/desugar-manifest.txt \
    --parser "lake exe nixparserlean --desugar --file"

# Run the eval manifest
cargo run --manifest-path e2e/runner/Cargo.toml -- \
    --manifest e2e/eval-manifest.txt \
    --parser "lake exe nixparserlean --eval --file"
```

## Repository layout

```
NixParserLean/
  Syntax.lean         — surface AST types
  Parser/
    Basic.lean        — parser state, token/whitespace/identifier/integer/path helpers
  Parser.lean         — recursive-descent expression grammar (imports Parser/Basic)
  Validate.lean       — surface semantic validation pass
  Core.lean           — Core AST (post-desugaring target language)
  Desugar.lean        — surface → Core lowering
  CoreValidate.lean   — invariant checks on the Core AST
  CoreEval.lean       — small evaluator over the Core AST
  HostEval.lean       — explicit host IO layer for relative imports
NixParserLean.lean    — re-exports every module above
Main.lean             — CLI entry point
e2e/
  manifest.txt              — parser/validator smoke manifest (default for runner)
  desugar-manifest.txt      — focused surface → Core fixtures
  eval-manifest.txt         — eval fragment fixtures + intentional eval-fail entries
  import-manifest.txt       — host import fixtures for --eval-imports
  external-manifest.example.txt — illustrates the file/url manifest forms
  corpus/smoke/             — committed Nix fixture files
  runner/                   — Rust e2e harness (src/main.rs)
examples/
  current-core-showcase/    — combined-feature example used as a regression test
blog/                       — development notes (one entry per significant change)
.tickets/                   — durable backlog (semantic milestones, debt)
docs/                       — this documentation
roadmap/                    — active long-horizon implementation plans
flake.nix                   — Nix flake (devShell + checks.e2e-smoke)
flagged.md                  — running list of shortcuts and debt worth tracking
```
