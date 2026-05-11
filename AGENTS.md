# AGENTS

## Mission

Build a powerful Lean implementation of Nix: a faithful parser, semantic model,
validation layer, and eventual proof-oriented core that can make real Nix code
legible to Lean.

This project is not just a parser experiment. The long-term aim is to turn Nix
from an operational language described mostly by implementation behavior into a
language with a precise Lean model: syntax, desugaring, validation, evaluation
semantics, and proofs that can be checked by the kernel.

## Opus Moderandi

Codex works on this repository by making ambitious progress in reviewable
increments.

- Read the existing code before changing it.
- Prefer the repository's current style over new abstractions.
- Keep each contribution scoped enough to review.
- Add smoke fixtures for parser and validation behavior.
- Run `nix develop -c lake build` after Lean changes.
- Run `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/manifest.txt`
  after parser, validator, CLI, or corpus changes.
- Use `docs/testing.md` as the full gate reference; run `nix flake check`
  when touching manifests, CLI behavior, JSON output, fuel, imports,
  evaluation, or the flake itself.
- Write a blog note for every significant contribution.
- Commit every significant contribution before starting the next one.
- Do not absorb unrelated worktree changes into a commit.

## Current Direction

The near-term priority is real Nix coverage:

- quoted and indented strings, including interpolation
- the full expression operator surface
- attribute access defaults and existence tests
- lambda parameter aliases and richer destructuring
- assertions and other common expression forms

The medium-term priority is sustainable scale:

- structured parse errors with source positions
- larger corpus infrastructure in the Rust harness
- clearer expected-failure tracking for real-world fixtures

The long-term priority is where Lean should pay off:

- separate surface syntax from a smaller core language
- make desugaring total and explicit
- define semantics over the core
- replace `partial` parser and validator debt with terminating definitions or
  well-scoped fuel
- prove useful invariants about parsing, validation, desugaring, and evaluation

## Commit Discipline

Every significant chunk should leave behind three things:

1. Code or documentation that advances the mission.
2. A blog post explaining the decision and its consequences.
3. A commit that contains only that chunk.

If the worktree contains unrelated untracked or modified files, leave them alone
unless the user explicitly asks to include them.
