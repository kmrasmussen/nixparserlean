# Agents and mission

The repository now has an `AGENTS.md`.

That file is more than local housekeeping. It states the mission directly:
build a powerful Lean implementation of Nix, not merely a parser that happens to
be written in Lean.

The distinction matters. A parser can stop once it accepts enough syntax. A Lean
implementation should keep going until syntax, validation, desugaring,
semantics, and proofs line up in one checked model.

The file also writes down the operating method for Codex work on the project:
read first, change in reviewable chunks, add smoke fixtures, run the Lean and
Rust harnesses, blog significant contributions, and commit them before moving
on. That is the opus moderandi for this codebase: ambition with a trail.

The immediate path remains practical. More real Nix syntax needs to parse. The
Rust harness needs to scale beyond committed smoke fixtures. The Lean code still
has `partial` debt. But those are now framed as steps toward the same end state:
a Nix model that can eventually be reasoned about inside Lean rather than only
tested from the outside.
