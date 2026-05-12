# NixParserLean Roadmap

This folder turns the project vision into reviewable work.

Start with [VISION.md](VISION.md). The short version is that NixParserLean is a
Lean-backed semantic lens for Nix: it should make real Nix code parseable,
explainable, analyzable, and eventually checkable by proofs over a small
explicit core.

Then use [00-current-state.md](00-current-state.md) for facts,
[01-phase-plan.md](01-phase-plan.md) for the capability sequence, and
[07-next-ticket-candidates.md](07-next-ticket-candidates.md) for the active
ticket funnel.

## Roadmap Files

| File | Purpose |
|---|---|
| [VISION.md](VISION.md) | Project vision, strategic principles, non-goals, and north-star demo |
| [00-current-state.md](00-current-state.md) | Factual snapshot: implemented behavior, gates, and current risks |
| [01-phase-plan.md](01-phase-plan.md) | Vision-derived capability plan for the next several waves |
| [02-parser-and-corpus.md](02-parser-and-corpus.md) | Real Nix coverage, corpus policy, parser totality, diagnostics |
| [03-core-semantics.md](03-core-semantics.md) | Core language, evaluator direction, analysis artifacts |
| [04-proofs-and-totality.md](04-proofs-and-totality.md) | Termination, fuel, desugaring and evaluator theorem program |
| [05-host-effects.md](05-host-effects.md) | Imports, paths, search paths, and effect boundaries |
| [06-project-operations.md](06-project-operations.md) | Ticket, test, docs, blog, and commit discipline |
| [07-next-ticket-candidates.md](07-next-ticket-candidates.md) | Ranked active funnel for the next tickets |
| [08-semantic-lens-alpha-sprint.md](08-semantic-lens-alpha-sprint.md) | Ambitious sprint plan for `TICKET-0061` through `TICKET-0080` |

## How To Use This Roadmap

Read [VISION.md](VISION.md) before changing the roadmap. Start work sessions
with [00-current-state.md](00-current-state.md) for facts, then
[01-phase-plan.md](01-phase-plan.md) for direction. Use
[07-next-ticket-candidates.md](07-next-ticket-candidates.md) to pick a narrow
slice, or [08-semantic-lens-alpha-sprint.md](08-semantic-lens-alpha-sprint.md)
when working through the current 20-ticket sprint. The other files explain the
strategic constraints behind each slice.

Each implementation ticket should answer four questions:

1. What does this make real Nix more legible about?
2. What core, validation, evaluation, or proof boundary does it clarify?
3. Which fixture or corpus row proves the behavior?
4. Which limitation remains intentionally out of scope?

For verification, use `docs/testing.md` as the full gate reference. At minimum,
run `nix develop -c lake build` after Lean changes and the relevant e2e
manifest after parser, validator, CLI, import, evaluation, or corpus changes.
Run `nix flake check` when touching manifests, CLI behavior, JSON output, fuel,
imports, evaluation, CI, or the flake itself.
