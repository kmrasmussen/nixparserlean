# NixParserLean Roadmap

NixParserLean should become a Lean-backed analysis and semantics engine for
Nix. The project is grounded in real Nix syntax and corpus coverage, but its
purpose is not to clone every operational detail of C++ Nix as quickly as
possible. The purpose is to make Nix code inspectable through a precise Lean
model: parse it, validate it, lower it into an explicit core, evaluate the
pure fragment, isolate host effects, and prove useful invariants about the
parts that matter.

The useful framing is:

```text
real Nix input
  -> source-positioned surface syntax
  -> semantic validation
  -> explicit core
  -> pure or host-aware evaluation lanes
  -> analysis artifacts and checked theorems
```

That makes the project more than a parser and less fragile than a premature
"verified Nix implementation" claim. The near-term product is a semantic lens:
a tool that can explain, classify, and check Nix programs while the verified
core grows in reviewable steps.

## Strategic Pillars

1. **Real Nix Legibility**
   The parser and corpus work must keep the project attached to real code.
   Features should increasingly be selected from pinned corpus blockers,
   representative examples, and source-positioned diagnostics rather than from
   an isolated grammar checklist.

2. **A Small Explicit Core**
   The core language is the proof target. Surface conveniences should either
   lower away or be documented as permanent semantic forms. A smaller core
   makes validation, evaluation, and theorem statements cheaper.

3. **Useful Analysis Before Completeness**
   The project should expose artifacts that are useful before full Nix
   evaluation exists: import graphs, binding shapes, attrpath structure,
   desugaring explanations, validation errors, and evaluator boundary
   diagnostics.

4. **Host Effects As A Named Boundary**
   Pure evaluation must stay filesystem-free. Imports, search paths, and host
   path behavior belong in `HostEval.lean` or a future explicit effect layer,
   with deterministic repo-local fixtures.

5. **Proofs That Follow The Model**
   Proof work should follow stable executable structure: total validators,
   total desugaring, restricted preservation, fuel monotonicity, determinism,
   and eventually a semantics relation. Avoid theorem targets that require
   modeling all of Nix at once.

6. **Reviewable Ambition**
   Roadmap work should be ambitious in direction and small in commits. Each
   significant contribution should leave code or docs, a blog note, and a
   focused commit that does not absorb unrelated worktree changes.

## What This Project Is Not Yet

- Not a drop-in replacement for Nix.
- Not a promise to model derivation realization, string contexts, store
  copying, or network fetchers in the near term.
- Not a parser-only project.
- Not a proof toy disconnected from nixpkgs-shaped input.
- Not a place for host filesystem behavior to leak into the pure core
  evaluator.

## Roadmap Files

| File | Purpose |
|---|---|
| [00-current-state.md](00-current-state.md) | Factual snapshot: implemented behavior, gates, and current risks |
| [01-phase-plan.md](01-phase-plan.md) | Strategy-to-execution plan for the next several waves |
| [02-parser-and-corpus.md](02-parser-and-corpus.md) | Real Nix coverage, corpus policy, parser totality, diagnostics |
| [03-core-semantics.md](03-core-semantics.md) | Core language, evaluator direction, analysis artifacts |
| [04-proofs-and-totality.md](04-proofs-and-totality.md) | Termination, fuel, desugaring and evaluator theorem program |
| [05-host-effects.md](05-host-effects.md) | Imports, paths, search paths, and effect boundaries |
| [06-project-operations.md](06-project-operations.md) | Ticket, test, docs, blog, and commit discipline |
| [07-next-ticket-candidates.md](07-next-ticket-candidates.md) | Ranked active funnel for the next tickets |

## How To Use This Roadmap

Start with [00-current-state.md](00-current-state.md) for facts, then
[01-phase-plan.md](01-phase-plan.md) for direction. Use
[07-next-ticket-candidates.md](07-next-ticket-candidates.md) to pick a narrow
slice. The other files explain the strategic constraints behind each slice.

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
