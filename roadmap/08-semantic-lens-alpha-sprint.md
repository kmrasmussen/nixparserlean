# Semantic Lens Alpha Sprint

This sprint intentionally includes all ready tickets from `TICKET-0061` through
`TICKET-0080`. The ambition is not to finish a grab bag. The ambition is to
land a first alpha of the semantic-lens vision:

```text
real Nix input
  -> structured diagnostics and JSON
  -> corpus lane discipline
  -> explicit host semantics
  -> clearer core policy
  -> wider proof surface
  -> durable local and CI gates
```

## Sprint Goal

By the end of the sprint, NixParserLean should be visibly more than a
parser/evaluator prototype. It should have stronger user-facing diagnostics,
more disciplined real-corpus workflows, clearer host-effect boundaries, a
better-defined core proof target, wider first proof slices, and a more durable
verification workflow.

## Sprint Scope

The sprint contains 20 tickets:

- `TICKET-0061`: Angle Search Path Prototype
- `TICKET-0062`: List Fuel Monotonicity
- `TICKET-0063`: Nonrecursive Static Attrset Fuel Monotonicity
- `TICKET-0064`: Determinism Modulo Fuel Statement
- `TICKET-0065`: Core `assert` Decision
- `TICKET-0066`: Dynamic Selection Default Policy
- `TICKET-0067`: External Corpus Lane Split Design
- `TICKET-0068`: Structured Parse Error Position Contract
- `TICKET-0069`: Parser Select Loop Totality
- `TICKET-0070`: Host Import Cycle Normalization Implementation
- `TICKET-0071`: Store Path Inertness Fixtures
- `TICKET-0072`: JSON Error Output Contract
- `TICKET-0073`: Surface Attrpath Nonempty Proof
- `TICKET-0074`: External Corpus Hash Enforcement
- `TICKET-0075`: Builtins Environment Shape
- `TICKET-0076`: Roadmap Ticket Batch Maintenance
- `TICKET-0077`: GitHub Actions Flake Check CI
- `TICKET-0078`: Local Pre-Push Gate
- `TICKET-0079`: CI Status And Required Checks Doc
- `TICKET-0080`: Core `with` Environment Invariant Theorem

## Tracks

### Track A: Semantic Artifacts

Goal: make the CLI and machine-readable output reflect the semantic-lens
vision.

Tickets:

- `TICKET-0068`: Structured Parse Error Position Contract
- `TICKET-0072`: JSON Error Output Contract

Sprint-level DoD:

- Parse errors have documented fields for message and position.
- JSON failures name the layer that failed.
- Text-mode behavior stays stable unless explicitly changed.
- The JSON contract is ready for future binding/import/desugar summaries.

Recommended order: `0068` before `0072`.

### Track B: Real Corpus Discipline

Goal: make real Nix coverage repeatable and easier to classify.

Tickets:

- `TICKET-0067`: External Corpus Lane Split Design
- `TICKET-0074`: External Corpus Hash Enforcement

Sprint-level DoD:

- The project has a documented external-lane strategy.
- Hash comments are enforced when present.
- Ordinary `nix flake check` remains network-free.
- Future corpus failures can become focused tickets instead of vague blockers.

Recommended order: `0067` before `0074`.

### Track C: Explicit Host Semantics

Goal: support more realistic host-backed imports without moving host IO into
the pure evaluator.

Tickets:

- `TICKET-0061`: Angle Search Path Prototype
- `TICKET-0070`: Host Import Cycle Normalization Implementation
- `TICKET-0071`: Store Path Inertness Fixtures

Sprint-level DoD:

- Explicit `--search-path NAME=PATH` style input resolves repo-local angle
  imports.
- No-search-path angle imports remain rejected.
- Relative import cycle detection uses documented normalized keys.
- Store-like paths remain inert and non-realizing.
- `CoreEval.lean` remains filesystem-free.

Recommended order: finish `0061` first because current uncommitted worktree
files already appear to belong to it, then `0070`, then `0071`.

### Track D: Core Policy

Goal: make the core smaller or better justified before larger proof claims.

Tickets:

- `TICKET-0065`: Core `assert` Decision
- `TICKET-0066`: Dynamic Selection Default Policy
- `TICKET-0075`: Builtins Environment Shape
- `TICKET-0080`: Core `with` Environment Invariant Theorem

Sprint-level DoD:

- `assert` has a permanent/temporary/pending classification.
- Dynamic selection defaults have a documented policy.
- Builtins have a first environment-shape design separating pure from
  host-backed behavior.
- `with` has a restricted lexical-first theorem target or proof.

Recommended order: `0065`, `0066`, `0075`, then `0080`.

### Track E: Proof Growth

Goal: expand checked guarantees without pretending to prove all of Nix.

Tickets:

- `TICKET-0062`: List Fuel Monotonicity
- `TICKET-0063`: Nonrecursive Static Attrset Fuel Monotonicity
- `TICKET-0064`: Determinism Modulo Fuel Statement
- `TICKET-0073`: Surface Attrpath Nonempty Proof

Sprint-level DoD:

- The proof surface grows beyond primitive unary/binary examples.
- Theorems or theorem targets clearly name their restrictions.
- Any blocker is captured as a precise theorem-shape or helper-shape note.
- Proof docs identify the next widening dependency.

Recommended order: `0062`, `0063`, `0064`, then `0073`.

### Track F: Parser Totality At The Artifact Boundary

Goal: remove termination debt where it protects source-positioned output.

Tickets:

- `TICKET-0069`: Parser Select Loop Totality

Sprint-level DoD:

- Selection parsing has a total fuel-bounded loop.
- Selection/path ambiguity fixtures still pass.
- Existing parse-failure offsets stay stable.

Recommended order: after `0068`, or with `0068`'s position contract copied
into the ticket acceptance notes.

### Track G: Project Durability

Goal: make the larger sprint safe to review, run, and resume.

Tickets:

- `TICKET-0076`: Roadmap Ticket Batch Maintenance
- `TICKET-0077`: GitHub Actions Flake Check CI
- `TICKET-0078`: Local Pre-Push Gate
- `TICKET-0079`: CI Status And Required Checks Doc

Sprint-level DoD:

- A local command runs the high-confidence gate.
- CI runs `nix flake check` without external corpus network dependency.
- Docs distinguish required, optional, and network-backed checks.
- The roadmap ticket funnel is refreshed at the end of the sprint.

Recommended order: `0077`, `0078`, `0079`, then `0076` as the closing
maintenance pass.

## Dependency Order

The safest critical path is:

1. Finish or explicitly park current `TICKET-0061` search-path work.
2. Land `TICKET-0068` and `TICKET-0072` so diagnostics and JSON contracts are
   stable early.
3. Land `TICKET-0067` and `TICKET-0074` so corpus work has lane and hash
   discipline.
4. Complete host semantics: `TICKET-0070`, then `TICKET-0071`.
5. Complete core policy: `TICKET-0065`, `TICKET-0066`, `TICKET-0075`,
   `TICKET-0080`.
6. Complete proof growth: `TICKET-0062`, `TICKET-0063`, `TICKET-0081`,
   `TICKET-0064`, `TICKET-0073`.
7. Complete parser totality: `TICKET-0069`, after the position contract is
   clear.
8. Complete durability work: `TICKET-0077`, `TICKET-0078`, `TICKET-0079`,
   `TICKET-0076`.

Some tracks can run in parallel if write sets stay separate. In practice, do
not overlap commits that both edit `CoreEval.lean`, CLI JSON output, or the
same e2e manifest.

## Sprint Definition Of Done

The sprint is done when:

1. Every ticket from `TICKET-0061` through `TICKET-0080` is marked
   `completed`, or explicitly split with a documented follow-up.
2. Each completed ticket has a blog note if it changed behavior, proof shape,
   corpus policy, CI, or roadmap direction.
3. The relevant gate for each ticket passed before its commit.
4. A final `nix flake check` passes, unless a platform or environment blocker
   is documented precisely.
5. [00-current-state.md](00-current-state.md),
   [07-next-ticket-candidates.md](07-next-ticket-candidates.md), and this
   sprint plan are refreshed after the final ticket.
6. `./scripts/open-tickets.sh` reports no remaining ready/in-progress tickets
   in the sprint range, unless the remaining ticket was intentionally split.

## Verification Policy

Use [../docs/testing.md](../docs/testing.md) as the full reference. The common
gates for this sprint are:

- Lean/proof/core changes: `nix develop -c lake build`
- Parser/validation changes:
  `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/manifest.txt`
- Evaluation changes:
  `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/eval-manifest.txt`
- Import changes:
  `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/import-manifest.txt`
- JSON changes:
  `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/json-manifest.txt`
- Fuel/proof-adjacent evaluator changes: the fuel manifests plus `lake build`
- CI/flake/pre-push changes: `nix flake check`
- External corpus changes: run the external manifest manually, but keep it out
  of ordinary flake checks.
