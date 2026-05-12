# Phase Plan

The next phase of NixParserLean should optimize for a coherent semantic lens,
not for a longer list of isolated Nix features. Work can proceed in parallel
when files are separate, but the intended dependency order is:

```text
real input -> better artifacts -> clearer core -> checked properties
```

## Phase 1: Make The Roadmap And Ticket Funnel Strategic

Goal: keep future work organized around the analysis-engine vision.

Why:

- The backlog has grown from parser expansion into host effects, proofs,
  corpus management, CI, and core semantics.
- The older roadmap mixed completed history with future strategy.
- Ticket choice should now be driven by leverage: legibility, core clarity,
  host boundary clarity, or proof value.

Exit criteria:

- The roadmap states the project vision and non-goals.
- Active tickets are grouped by strategic workstream.
- Completed ticket waves remain historical context, not the main roadmap.

## Phase 2: Build User-Visible Semantic Artifacts

Goal: make the tool useful as an analysis engine before full Nix evaluation is
possible.

Useful artifacts include:

- structured parse and validation errors with source positions;
- import graph or import-boundary summaries;
- attrpath and binding-shape summaries;
- desugar explanations for selected surface forms;
- JSON output that downstream tools can consume reliably.

Why this comes early:

- It gives the project a practical surface beyond "can parse/evaluate this
  fixture".
- It makes future proof and core work easier to inspect.
- It turns corpus blockers into actionable categories.

Exit criteria:

- At least one machine-readable artifact is stable enough to document.
- JSON/error contracts are covered by e2e fixtures.
- Source positions are preserved across the relevant parser path.

Primary ticket lane: `TICKET-0068`, `TICKET-0072`, then targeted follow-ups.

## Phase 3: Keep Real Nix Coverage Honest

Goal: use pinned corpus growth to select parser and validation work.

Why:

- Real Nix coverage is the credibility layer.
- Green small fixtures are not enough once the parser is broad.
- Corpus lanes can show whether a blocker is parser, validation, desugar,
  core, host, or evaluator work.

Exit criteria:

- External corpus rows are split or reported by lane.
- Hash or pinning policy is enforceable enough for repeatability.
- New blockers become small tickets with a clear gate.

Primary ticket lane: `TICKET-0067`, `TICKET-0074`, then the next pinned corpus
wave.

## Phase 4: Clarify Host Effects Without Polluting Pure Semantics

Goal: support more realistic import and path behavior while keeping `CoreEval`
pure.

Why:

- Real Nix code relies on imports and search paths.
- Host-backed behavior is useful for analysis, but it must stay explicit.
- The pure evaluator should remain a proof-friendly semantics for a bounded
  fragment.

Exit criteria:

- Angle search paths work only through explicit repo-local configuration.
- Import cycle detection has deterministic normalized keys.
- Store-like paths remain inert until a store model exists.
- Host-aware behavior is documented as separate from pure evaluation.

Primary ticket lane: `TICKET-0061`, `TICKET-0070`, `TICKET-0071`.

## Phase 5: Shrink Or Justify The Core

Goal: make the core language a stable proof target.

Why:

- The core still contains surface-like forms that were useful for fast
  evaluator growth.
- Proofs become cheaper when lowering decisions are explicit.
- Some forms, such as `with`, may be permanent but need named invariants.

Exit criteria:

- `assert` is either lowered, retained with a clear reason, or given a proof
  plan.
- Dynamic selection defaults have a no-duplication or permanent-core policy.
- Builtins have an explicit environment shape before ad hoc evaluator growth.
- `with` has a restricted invariant theorem target.

Primary ticket lane: `TICKET-0065`, `TICKET-0066`, `TICKET-0075`,
`TICKET-0080`.

## Phase 6: Widen Proofs Along Executable Boundaries

Goal: grow checked theorem value from stable executable subsets.

Why:

- Validators, desugaring, and evaluator fuel already provide proof-friendly
  seams.
- Fuel monotonicity is useful only if it expands beyond primitive operators.
- The proof program should stay connected to tested behavior.

Exit criteria:

- List and nonrecursive static attrset fuel monotonicity are stated or proven.
- Determinism modulo fuel is stated for the same restricted subset.
- Surface attrpath nonempty facts support desugar/core validation reasoning.
- Theorems clearly name their restrictions.

Primary ticket lane: `TICKET-0062`, `TICKET-0063`, `TICKET-0064`,
`TICKET-0073`.

## Phase 7: Reduce Parser `partial` Debt Where It Protects Artifacts

Goal: remove termination debt from parser paths that matter for diagnostics and
analysis output.

Why:

- Parser totality is not just hygiene; it supports source-positioned artifacts.
- Mechanical fuel slices are safer after the parser behavior is covered by
  manifests.
- Totality work should not destabilize parse offsets.

Exit criteria:

- Selection parsing loops are fuel-bounded without changing successful parse
  output.
- Existing parse-failure offsets stay stable.
- Parser docs describe the position contract.

Primary ticket lane: `TICKET-0069` after the structured error contract is
clear enough.

## Phase 8: Make Project Operations Match The Ambition

Goal: keep the project easy to resume and hard to accidentally regress.

Why:

- Roadmap, tickets, blog notes, examples, and manifests are now part of the
  engineering system.
- CI and local gates make ambitious work less brittle.

Exit criteria:

- Roadmap maintenance happens as a recurring ticket, not as memory.
- CI status and local pre-push expectations are documented.
- `nix flake check` has a GitHub Actions path if the repository is published
  with CI enabled.

Primary ticket lane: `TICKET-0076`, `TICKET-0077`, `TICKET-0078`,
`TICKET-0079`.
