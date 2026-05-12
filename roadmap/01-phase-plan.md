# Phase Plan

The phase plan derives from [VISION.md](VISION.md). Each phase names a
capability the project should gain, not just a category of contributor work.

The intended progression is:

```text
read real Nix
  -> explain structure
  -> explain semantics
  -> stabilize core
  -> check the model
  -> make the workflow durable
```

Phases can overlap when their files and risks are separate. A ticket should
still land as one reviewable chunk with fixtures, docs, and a clear gate.

## Phase 1: Read Real Nix

Vision link: real Nix input must become source-positioned surface syntax.

User-visible capability:

- Parse pinned real Nix files and representative smoke fixtures.
- Preserve enough position information to make failures actionable.
- Classify corpus failures by parser, validation, desugar, core validation,
  evaluation, or host-effect lane.

Concrete work:

- `TICKET-0067`: External Corpus Lane Split Design
- `TICKET-0074`: External Corpus Hash Enforcement
- future pinned corpus waves from new nixpkgs areas

Exit criteria:

- External corpus reporting shows which layer blocks each non-pass row.
- New corpus rows are pinned or hash-checked enough to be repeatable.
- Parser work is selected from corpus blockers or explicit diagnostic gaps.

## Phase 2: Explain Nix Structure

Vision link: users should see bindings, attrpaths, imports, and validation
boundaries before full evaluation exists.

User-visible capability:

- Emit structured parse and validation diagnostics with source positions.
- Emit JSON stable enough for downstream tools.
- Begin exposing binding, attrpath, and import-boundary summaries.

Concrete work:

- `TICKET-0068`: Structured Parse Error Position Contract
- `TICKET-0072`: JSON Error Output Contract
- follow-up ticket for first binding or attrpath summary artifact

Exit criteria:

- Error output has a documented shape and e2e fixtures.
- A downstream consumer can rely on stable JSON fields for failures.
- At least one structural artifact exists beyond raw parse/desugar output.

## Phase 3: Explain Nix Semantics

Vision link: surface syntax should lower into an explicit core, and unsupported
semantics should be named precisely.

User-visible capability:

- Show desugared core for selected expressions/files.
- Distinguish pure evaluation failures from host-effect requirements.
- Explain import/search-path behavior in deterministic repo-local cases.

Concrete work:

- `TICKET-0061`: Angle Search Path Prototype
- `TICKET-0070`: Host Import Cycle Normalization Implementation
- `TICKET-0071`: Store Path Inertness Fixtures
- follow-up ticket for a desugar explanation artifact

Exit criteria:

- Angle imports work only with explicit `--search-path NAME=PATH` style input.
- Import cycle detection uses documented normalized keys.
- Store-like paths are documented and tested as inert values.
- CLI output names whether a failure is pure semantic, host-effect, or
  intentionally unsupported.

## Phase 4: Stabilize The Core

Vision link: the core is the proof target and the main explanation artifact.

User-visible capability:

- Users can inspect a smaller, clearer core rather than a mirror of every
  surface construct.
- Core validation documents the invariants evaluation and proofs can rely on.
- Permanent core forms have explicit semantic reasons.

Concrete work:

- `TICKET-0065`: Core `assert` Decision
- `TICKET-0066`: Dynamic Selection Default Policy
- `TICKET-0075`: Builtins Environment Shape
- `TICKET-0080`: Core `with` Environment Invariant Theorem

Exit criteria:

- `assert` is lowered, retained with a reason, or given a proof plan.
- Dynamic selection defaults have a no-duplication or permanent-core policy.
- Builtins enter through an explicit environment shape.
- `with` has a named restricted invariant theorem target.

## Phase 5: Check The Model

Vision link: selected artifacts and semantic fragments should become checked
Lean facts, not just tested behavior.

User-visible capability:

- Documentation can say which invariants are proved for which fragment.
- Fuel behavior becomes predictable for growing pure subsets.
- Desugar/core-validation claims are backed by checked lemmas where possible.

Concrete work:

- `TICKET-0062`: List Fuel Monotonicity
- `TICKET-0063`: Nonrecursive Static Attrset Fuel Monotonicity
- `TICKET-0064`: Determinism Modulo Fuel Statement
- `TICKET-0073`: Surface Attrpath Nonempty Proof

Exit criteria:

- Theorems clearly name their restrictions.
- Lists and nonrecursive static attrsets are covered or explicitly staged.
- Determinism is stated for the same subset before the subset grows further.
- Surface attrpath facts support desugar/core-validation reasoning.

## Phase 6: Retire Termination Debt Where It Affects The Lens

Vision link: source-positioned artifacts and checked layers should not rest on
unbounded parser helpers forever.

User-visible capability:

- Parser behavior stays stable while selected loops become total.
- Parse failure offsets remain predictable.
- The position contract is protected by tests.

Concrete work:

- `TICKET-0069`: Parser Select Loop Totality
- future tickets for remaining parser helper families once diagnostics are
  stable

Exit criteria:

- Selection parsing loops are fuel-bounded without changing successful parse
  output.
- Existing parse-failure offsets stay stable.
- Parser docs describe the position contract.

## Phase 7: Make The Workflow Durable

Vision link: reviewable ambition needs reliable gates, CI, and roadmap hygiene.

User-visible capability:

- Contributors know which gate protects each kind of change.
- CI and local pre-push flows catch ordinary regressions.
- Roadmap and ticket state remain useful after several completed slices.

Concrete work:

- `TICKET-0076`: Roadmap Ticket Batch Maintenance
- `TICKET-0077`: GitHub Actions Flake Check CI
- `TICKET-0078`: Local Pre-Push Gate
- `TICKET-0079`: CI Status And Required Checks Doc

Exit criteria:

- Roadmap refreshes are recurring maintenance, not memory.
- CI status and local gates are documented.
- `nix flake check` has a GitHub Actions path if the repository is published
  with CI enabled.
