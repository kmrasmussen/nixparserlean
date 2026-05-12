# Phase Plan

The next wave should turn the completed backlog into a fresh, coherent program
instead of extending the old ticket list mechanically. Adjacent phases can
overlap when their write sets are separate, but each `.tickets` entry should
still land as one reviewable chunk.

## Phase 1: Generate The Next Ticket Wave

Goal: convert this roadmap into a small set of future `.tickets`.

Why now:

- The visible backlog through `TICKET-0051` is closed.
- The first pinned external corpus set is green.
- Several design notes now name concrete next implementation slices.

Exit criteria:

- A broad queue of new tickets exists, each with a clear acceptance gate.
- Each ticket maps back to one roadmap milestone or design document.
- No ticket tries to solve parser totality, host imports, or evaluator proofs
  all at once.

Seed from [07-next-ticket-candidates.md](07-next-ticket-candidates.md).

## Phase 2: Host Imports That Can Carry Functions

Goal: make `--eval-imports` useful for imported function-valued files without
putting filesystem behavior into `CoreEval`.

Why next:

- The current imported-function diagnostic is documented and tested.
- `docs/host-effect-evaluator-shape.md` chooses the next architecture.
- Real Nix module patterns need imports that can produce functions.

Exit criteria:

- A repo-local fixture imports a function and applies it successfully.
- Existing representable imported values still reify as before.
- `CoreEval.lean` remains filesystem-free.
- The old imported-function rejection row is either retired or narrowed to a
  still-unsupported case.

## Phase 3: Parser Totality Slices

Goal: reduce parser `partial` debt without destabilizing source positions.

Why now:

- Feature coverage has stabilized enough for mechanical parser work.
- The parser termination strategy chooses explicit fuel first.
- Additive/multiplicative loops are narrow and good first targets.

Exit criteria:

- `parseAdd` and `parseMul` loops use total fuel-bounded helpers.
- Comment skipping and string scanning have follow-up tickets or are converted.
- Default and external parser manifests remain stable.
- Parse error offsets for existing failure fixtures do not move.

## Phase 4: Widen Semantic Fuel Proofs

Goal: turn the first monotonicity theorem into a growing semantic proof surface.

Why after the first theorem:

- The primitive literal/binary proof harness is checked.
- Fuel behavior has runtime e2e coverage at low, sufficient, and high fuel.
- The next widening steps can stay small.

Exit criteria:

- Unary primitive monotonicity lands.
- List monotonicity lands for primitive literal elements.
- Non-recursive static attrset monotonicity is stated or proven.
- Determinism modulo fuel is stated for the same restricted subset.

## Phase 5: Core Simplification Before Big Preservation Proofs

Goal: shrink or justify surface-like core forms before proving too much about
them.

Why now:

- Static selection defaults already lower away.
- `with`, `assert`, dynamic selection defaults, and environment behavior remain
  semantic decisions.
- Preservation proofs get cheaper when the core is smaller.

Exit criteria:

- One additional surface-like form lowers away or is documented as permanent.
- The behavior change has eval/desugar fixtures.
- Any behavior-preserving lowering gets a theorem statement or checked lemma.

## Phase 6: External Corpus Expansion

Goal: make the next corpus wave the driver for real Nix coverage.

Why after the first green set:

- The first 15 pinned nixpkgs rows all pass.
- The runner and `external-summary.sh` can report blocker categories.
- New rows can now expose the next real blockers.

Exit criteria:

- Add a second pinned corpus set.
- Keep all rows immutable and documented.
- Classify failures into parser, validation, core, or eval blockers.
- Do not require network-backed external runs in ordinary flake checks.

## Phase 7: Host Path Policy

Goal: make host path behavior deterministic before adding more import forms.

Exit criteria:

- Relative import recursion detection has a normalization policy and tests.
- Angle search paths have a repo-local `--search-path NAME=PATH` prototype or
  a ticket ready for it.
- Pure path values remain inert text.

## Phase 8: Operations And Roadmap Hygiene

Goal: keep future sessions easy to resume.

Exit criteria:

- `./scripts/open-tickets.sh` remains the first backlog check.
- Roadmap files are refreshed after every 3-5 completed tickets.
- `07-next-ticket-candidates.md` is updated before creating a new ticket wave.
- Significant roadmap shifts get a blog note and a small commit.
