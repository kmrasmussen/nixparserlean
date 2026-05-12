# Next Ticket Candidates

This file is the active ticket funnel. It is not a second tracker; the
`.tickets/` directory remains the source of truth once a ticket exists. This
page answers a different question: which ready tickets best advance the
strategy, and why?

The current strategic bias is:

```text
make Nix legible -> expose stable artifacts -> clarify semantics -> prove it
```

## Recommended Order

### 1. Analysis Artifacts And Diagnostics

These tickets make the project useful as a semantic lens before full Nix
evaluation exists.

- `TICKET-0068`: Structured Parse Error Position Contract
- `TICKET-0072`: JSON Error Output Contract

Why first:

- Source-positioned diagnostics are the foundation for serious analysis output.
- JSON/error stability gives future tools something to consume.
- These tickets make corpus blockers easier to classify.

Good next slice: start with `TICKET-0068`, then make `TICKET-0072` consume the
same error shape instead of inventing a parallel contract.

### 2. Real Corpus Discipline

These tickets keep the parser and validator honest against real Nix while
avoiding network-dependent local gates.

- `TICKET-0067`: External Corpus Lane Split Design
- `TICKET-0074`: External Corpus Hash Enforcement

Why next:

- A broad parser needs corpus infrastructure more than isolated feature
  guessing.
- Lane splitting makes it clear whether a row is blocked by parse, validation,
  desugar, core validation, evaluation, or host effects.
- Hash enforcement keeps pinned rows reviewable and repeatable.

Good next slice: design the lane split before adding another corpus wave, then
enforce hashes or immutable pins.

### 3. Explicit Host Semantics

These tickets make imports and paths more realistic without weakening the pure
core evaluator.

- `TICKET-0061`: Angle Search Path Prototype
- `TICKET-0070`: Host Import Cycle Normalization Implementation
- `TICKET-0071`: Store Path Inertness Fixtures

Why now:

- Search paths are common in real Nix, but must be explicit and repo-local.
- Cycle normalization protects host import behavior from path aliases.
- Store path inertness documents what the project deliberately does not model
  yet.

Good next slice: `TICKET-0061` is already partly represented by current
uncommitted worktree files, so finish or review that work before starting a
separate host ticket.

### 4. Core Policy Decisions

These tickets decide what belongs in the proof target before proofs grow too
wide.

- `TICKET-0065`: Core `assert` Decision
- `TICKET-0066`: Dynamic Selection Default Policy
- `TICKET-0075`: Builtins Environment Shape
- `TICKET-0080`: Core `with` Environment Invariant Theorem

Why after host/artifact work:

- The core should support useful explanations and checked invariants.
- `assert`, dynamic defaults, builtins, and `with` affect evaluator behavior
  and theorem statements.
- These decisions should be made with fixtures and docs, not only comments.

Good next slice: decide `assert` before widening evaluator preservation claims.

### 5. Proof Growth

These tickets widen checked guarantees while staying inside restricted,
executable subsets.

- `TICKET-0062`: List Fuel Monotonicity
- `TICKET-0063`: Nonrecursive Static Attrset Fuel Monotonicity
- `TICKET-0064`: Determinism Modulo Fuel Statement
- `TICKET-0073`: Surface Attrpath Nonempty Proof

Why this order:

- Lists are the smallest recursive evaluator walker that avoids environments.
- Nonrecursive static attrsets add binding structure without thunks.
- Determinism should be stated for the same subset before growing further.
- Attrpath facts feed desugar/core validation reasoning.

Good next slice: prove or state list monotonicity with explicit exclusions.

### 6. Parser Totality And Position Preservation

These tickets reduce parser termination debt where it matters for analysis
artifacts.

- `TICKET-0069`: Parser Select Loop Totality

Why later:

- The structured parse error contract should define what cannot move.
- Fuel-bounding parser loops is valuable only if it preserves source offsets
  and parse behavior.

Good next slice: run this after `TICKET-0068` or explicitly include offset
stability in the acceptance gate.

### 7. Project Operations

These tickets keep the engineering loop durable.

- `TICKET-0076`: Roadmap Ticket Batch Maintenance
- `TICKET-0077`: GitHub Actions Flake Check CI
- `TICKET-0078`: Local Pre-Push Gate
- `TICKET-0079`: CI Status And Required Checks Doc

Why not ignore them:

- The project now relies on many e2e lanes and docs.
- CI and local gates make the ambitious semantic work easier to review.
- Roadmap refreshes should happen before the ticket funnel becomes stale.

Good next slice: use `TICKET-0076` after the next few completed tickets to keep
this file short and current.

## Historical Ticket Waves

The first two waves have already been promoted to `.tickets` and partly
completed. Keep them as context only; do not treat this list as the active
plan.

Completed first wave:

- `TICKET-0052`: Host Value Slots For Imported Closures
- `TICKET-0053`: Fuel-Bound `parseAdd` And `parseMul` Loops
- `TICKET-0054`: Unary Primitive Fuel Monotonicity
- `TICKET-0055`: Relative Import Path Normalization Policy
- `TICKET-0056`: Second External Corpus Wave

Completed second-wave items:

- `TICKET-0057`: Comment And Whitespace Scanner Totality
- `TICKET-0058`: String Scanner Totality
- `TICKET-0059`: Static Selection Default Preservation Theorem, completed as
  a shape theorem
- `TICKET-0060`: Core `with` Decision

Ready items from the second wave are ranked above by strategy rather than by
ticket number.
