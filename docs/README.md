# NixParserLean Documentation

NixParserLean is a Nix language parser and semantic model written in Lean 4. The project aims to build a formally-grounded representation of Nix expressions, with a separate Rust harness for end-to-end corpus testing.

## Goals

- Model Nix syntax and semantics faithfully in Lean 4's type system.
- Build a handwritten, readable parser that makes the underlying grammar visible.
- Detect semantic errors (duplicate bindings, conflicting attribute paths) at validation time.
- Drive parser coverage with a growing corpus of real-world Nix files.

## Non-goals (current)

- Source-preserving or round-tripping output (comments are discarded as whitespace).
- Complete Nix language support in a single pass — coverage grows incrementally.
- Proof of semantic properties — the model is a prerequisite, not the finished product.

## Documents

| File | Contents |
|---|---|
| [architecture.md](architecture.md) | Component layout and data flow |
| [ast.md](ast.md) | AST node reference |
| [parser.md](parser.md) | Parser internals and operator precedence |
| [core.md](core.md) | Core AST and surface-to-core desugaring |
| [testing.md](testing.md) | Testing strategy, manifest format, and e2e runner |
| [scaling-plan.md](scaling-plan.md) | Roadmap for growing the parser and corpus |

## Quick start

```sh
# Build the Lean parser
lake build

# Parse a file
lake exe nixparserlean --file path/to/file.nix

# Print the desugared core AST
lake exe nixparserlean --desugar --file path/to/file.nix

# Parse an inline expression
lake exe nixparserlean '{ x = 1; }'

# Run the e2e smoke corpus
cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/manifest.txt
```

## Repository layout

```
NixParserLean/
  Syntax.lean      — AST types
  Parser.lean      — handwritten recursive-descent parser
  Validate.lean    — semantic validation pass
Main.lean          — CLI entry point
e2e/
  manifest.txt     — test corpus declarations
  corpus/smoke/    — committed Nix fixture files
  runner/          — Rust e2e harness (src/main.rs)
blog/              — development notes
docs/              — this documentation
flake.nix          — Nix flake (devShell + CI check)
```
