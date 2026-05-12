# NixParserLean Roadmap

This folder is the active roadmap after the ticket backlog through
`TICKET-0051` was closed. It should describe what is true now, what is
strategically next, and which future slices are ready to become `.tickets`.

The project has moved past the first parser-expansion wave. The parser handles
the first pinned external nixpkgs corpus, validation and core validation have
separate total fuel-bounded layers, desugaring has a total fuel-bounded walk,
evaluation covers a useful pure core fragment, and host imports have an explicit
IO boundary.

The next roadmap should optimize for leverage:

1. **Grow real-Nix coverage deliberately.** Expand the external corpus and
   classify blockers rather than guessing at syntax features.
2. **Make host imports useful without polluting pure evaluation.** Imported
   closures and path policy are the next host-effect frontier.
3. **Remove `partial` debt in small slices.** Start with parser loops and
   scanner helpers, preserving source positions.
4. **Widen checked proof value.** Turn the first fuel/desugar theorems into a
   broader semantic proof program.
5. **Keep the core small enough to reason about.** Lower or justify remaining
   surface-like core forms before proving too much about them.
6. **Generate tickets from roadmap slices.** The roadmap is now the source of
   future `.tickets`, not a parallel stale list.

## Files

| File | Purpose |
|---|---|
| [00-current-state.md](00-current-state.md) | Snapshot of what works, what is tested, and what remains load-bearing debt |
| [01-phase-plan.md](01-phase-plan.md) | Recommended order for the next project wave |
| [02-parser-and-corpus.md](02-parser-and-corpus.md) | Parser coverage, external corpus growth, and parser-totality direction |
| [03-core-semantics.md](03-core-semantics.md) | Core language, evaluator, imports, paths, and semantic boundary work |
| [04-proofs-and-totality.md](04-proofs-and-totality.md) | Termination, desugaring proofs, evaluator fuel theorems |
| [05-host-effects.md](05-host-effects.md) | Import/path IO boundary and future host-backed semantics |
| [06-project-operations.md](06-project-operations.md) | Tickets, testing, docs, and commit cadence |
| [07-next-ticket-candidates.md](07-next-ticket-candidates.md) | Concrete slices ready to turn into future `.tickets` |

## How To Use This Roadmap

- Start each work session with [00-current-state.md](00-current-state.md),
  then [01-phase-plan.md](01-phase-plan.md).
- Pick one candidate from
  [07-next-ticket-candidates.md](07-next-ticket-candidates.md) and turn it into
  one `.tickets/TICKET-XXXX` entry before implementation.
- Keep ticket scope narrow enough for one reviewable commit.
- Add or update e2e fixtures before calling a language feature complete.
- Run `nix develop --command lake build` after Lean changes.
- Run the relevant e2e manifests, or `nix flake check` when manifests,
  CLI behavior, core validation, evaluation, or the flake itself changes.
- Keep `flagged.md` aligned with roadmap risk: either remove a caveat when it
  is fixed or narrow it so it remains useful.
- Use `./scripts/open-tickets.sh` during maintenance passes to list any
  non-completed `.tickets` entries.
