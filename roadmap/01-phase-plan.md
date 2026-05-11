# Phase Plan

The roadmap should move in phases that each improve one project dimension
without destabilizing the rest. The order below is recommended; adjacent
phases can overlap only when their write sets and proof obligations are
clearly separate.

## Phase 1: External Corpus Ratchet

Goal: make real Nix surface coverage the next source of truth.

Status: complete for the first pinned corpus set; all 15 rows currently pass.

Why now:

- The initial backlog through `TICKET-0031` was completed.
- The parser already handles a wide smoke subset.
- The external manifest has already turned the first blocker set into concrete
  smoke fixtures and passing pinned rows.

Exit criteria:

- `spaced-dynamic-selection` blockers move to `pass` or a later, narrower
  blocker.
- `quoted-inherit-name` has smoke and external coverage.
- `path-argument-dot-file` has a parser decision and fixture.
- `indented-string-escape` has a documented string escape policy.
- External manifest notes remain stable and blocker categories are meaningful.

Recommended first ticket:

```text
TICKET: External corpus blocker ratchet - spaced dynamic selection
```

## Phase 2: Documentation Freshness And Contract Cleanup

Goal: make docs match current behavior before more semantics are added.

Why now:

- Some old docs still describe path values as unsupported even though the
  evaluator now has `Value.path`.
- The AGENTS checklist under-runs current flake coverage.
- Roadmap consumers need reliable layer boundaries.

Exit criteria:

- `docs/core.md`, `docs/testing.md`, `docs/import-and-path-boundary.md`, and
  `flagged.md` agree with current code and e2e manifests.
- `AGENTS.md` mentions the broader flake/e2e gate, or clearly delegates to
  `docs/testing.md`.
- Every caveat in `flagged.md` points to a roadmap file or future ticket.

Recommended first ticket:

```text
TICKET: Refresh docs after path, fuel, and validator totality work
```

## Phase 3: Core Simplification

Goal: shrink the core language so proofs target fewer constructs.

Why now:

- Core is still close to surface syntax.
- Several evaluator behaviors duplicate source-level forms that could lower
  into fewer core primitives.
- Core validation should become a smaller set of invariants, not a second
  surface validator.

Candidate reductions:

- Lower `assert` into a core primitive with explicit evaluation rule or keep
  it as one of a small set of control forms.
- Decide whether `with` remains core syntax or lowers into explicit lookup
  environment behavior.
- Decide whether selection defaults should stay core or lower into a smaller
  conditional/missing-selection representation.
- Split path values from import path arguments more explicitly if needed.

Exit criteria:

- `docs/core.md` names the intended minimal core.
- At least one surface form lowers into a smaller core representation.
- Existing eval fixtures still pass.
- Any behavior-preserving desugar change gets a focused theorem or TODO
  theorem statement.

## Phase 4: Desugaring Proof Program

Goal: turn runtime core-validation backstops into checked desugaring facts.

Why now:

- The first static-path and merge lemmas exist.
- Empty static paths are rejected explicitly.
- Validators are total enough to serve as proof targets.

Exit criteria:

- Prove non-empty parser/surface attrpaths cannot hit the desugar empty-path
  branch.
- Prove a restricted `surface validate -> desugar -> core validate` theorem
  for static attrsets without dynamic paths.
- Prove static merge uniqueness for a useful subset.
- Record assumptions about dynamic paths in theorem names or docs.

Recommended first ticket:

```text
TICKET: Restricted static attrset desugar-core-validation theorem
```

## Phase 5: Evaluator Semantics And Fuel Theorems

Goal: turn entry-step fuel into a proof-friendly semantics.

Why now:

- Fuel now has a deterministic policy.
- Low-fuel success/failure behavior is tested.
- Evaluation already covers enough features to make monotonicity useful.

Exit criteria:

- State and prove monotonicity for literals and binary expressions.
- Extend monotonicity to lists and non-recursive attrsets.
- State determinism modulo fuel for successful runs on a small subset.
- Decide whether to introduce a separate small-step relation before widening
  to closures and thunks.

Recommended first ticket:

```text
TICKET: Fuel monotonicity for literals and binary expressions
```

## Phase 6: Host Import Semantics

Goal: grow imports without muddying pure evaluation.

Why now:

- Relative imports work but are eager and value-only.
- Imported closures are rejected at reification.
- Real Nix modules increasingly need imports as values or functions.

Exit criteria:

- Decide whether imported functions remain unsupported, become directly
  evaluable, or require a host-aware value form.
- Add fixtures for imported attrset functions if supported or sharper
  diagnostics if rejected.
- Normalize relative paths only in host IO, not in pure path values.
- Keep angle path and store semantics explicitly out of scope until designed.

## Phase 7: Parser Termination

Goal: remove or isolate parser `partial` debt.

Why late:

- Parser termination is invasive.
- Feature coverage and external corpus behavior should stabilize first.

Exit criteria:

- Pick explicit parser fuel or `decreasing_by` on input length.
- Convert one parser subcluster first, probably string/path lexing helpers.
- Preserve structured parse positions.
- Keep all parser and external corpus expectations stable.

## Phase 8: Operating System For The Project

Goal: make future sessions easy to resume.

Exit criteria:

- New tickets are generated from this roadmap, not ad hoc memory.
- Each completed ticket has plan, resolution, verification, blog note, and
  commit.
- `nix flake check` stays the default high-confidence gate.
- External corpus drift can be summarized with one command.
