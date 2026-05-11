# NixParserLean Roadmap

This folder is the active project roadmap as of the post-`TICKET-0031`
state. It sits at the repository root so it is easy to find during working
sessions; older long-horizon notes remain under `docs/roadmap/`.

The project has moved past the initial "can Lean parse useful Nix?" stage.
The parser covers a broad surface subset, validation and core validation have
separate error layers, desugaring has its first checked invariants, evaluation
handles a meaningful core fragment, host imports have an explicit IO boundary,
and all tickets through `TICKET-0031` are complete.

The next roadmap should therefore optimize for leverage:

1. **Ratchet real Nix coverage.** Turn the pinned external blockers into
   parser/evaluator work, one construct at a time.
2. **Stabilize the core.** Make the surface-to-core boundary smaller,
   better specified, and easier to prove against.
3. **Earn Lean's proof value.** Replace broad `partial` islands with total or
   fuel-bounded definitions, then harvest focused theorems.
4. **Keep host effects explicit.** Grow import/path semantics without letting
   filesystem behavior leak into pure evaluation.
5. **Keep the work reviewable.** Each roadmap item should land with fixtures,
   docs or a blog note, and a small commit.

## Files

| File | Purpose |
|---|---|
| [00-current-state.md](00-current-state.md) | Snapshot of what works, what is tested, and what remains load-bearing debt |
| [01-phase-plan.md](01-phase-plan.md) | Recommended order of execution across the next project phases |
| [02-parser-and-corpus.md](02-parser-and-corpus.md) | Parser coverage and external corpus ratchet |
| [03-core-semantics.md](03-core-semantics.md) | Core language, evaluator, imports, paths, and semantic boundary work |
| [04-proofs-and-totality.md](04-proofs-and-totality.md) | Termination, desugaring proofs, evaluator fuel theorems |
| [05-host-effects.md](05-host-effects.md) | Import/path IO boundary and future host-backed semantics |
| [06-project-operations.md](06-project-operations.md) | Tickets, testing, docs, and commit cadence |

## How To Use This Roadmap

- Start each new work session with `00-current-state.md` and
  `01-phase-plan.md`.
- Convert one roadmap milestone into one `.tickets/TICKET-XXXX` entry before
  implementation, unless the work is a tiny documentation cleanup.
- Add or update e2e fixtures before calling a language feature complete.
- Run `nix develop --command lake build` after Lean changes.
- Run the relevant e2e manifests, or `nix flake check` when manifests,
  CLI behavior, core validation, evaluation, or the flake itself changes.
- Keep `flagged.md` aligned with roadmap risk: either remove a caveat when it
  is fixed or narrow it so it remains useful.
