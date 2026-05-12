# TICKET-0065: Core `assert` Decision

## Problem
`assert` remains a core form. It may be permanent control syntax, or it may be
better modeled as a smaller core primitive or validation/evaluation construct.

## Goal
Decide and document the long-term core status of `assert`, with fixtures if a
lowering or evaluator change lands.

## In Scope
- Compare keeping `assert` as core syntax versus lowering or modeling it
  differently.
- Update `docs/core.md` and roadmap notes.
- Add desugar/eval fixtures if behavior changes.
- Create a follow-up implementation ticket if this is design-only.

## Out of Scope
- Full exception semantics.
- Proof of assertion preservation.
- Changes to parser syntax.

## Acceptance Criteria
1. `assert` is classified as permanent, temporary, or pending with rationale.
2. Any behavior change has e2e coverage.
3. Eval/desugar manifests pass if code changes.
4. The next implementation step is concrete.

## Resolution

Classified `assert` as permanent core control syntax.

Rationale:

- the current core has no explicit bottom, throw, or error-value form;
- lowering `assert condition; body` to existing core syntax would either erase
  assertion failure or require inventing a new error primitive;
- the evaluator already gives `assert` direct control behavior: evaluate the
  condition first, continue with the body only on `true`, and fail with an
  evaluator error on `false` or non-boolean conditions;
- real Nix corpus code uses `assert` as a control check, so keeping it named in
  core makes validation, evaluation, and future proof statements clearer.

No executable behavior changed. The next implementation step is to shape future
preservation/progress-style proof tickets around evaluator errors: successful
evaluation produces values, while failed assertions remain errors, not values.

Verification:

- focused temporary eval manifest covering `e2e/corpus/smoke/assert.nix` and
  `e2e/corpus/smoke/eval-if-assert.nix`:
  `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest /tmp/<assert-manifest>`

Note: the full `e2e/eval-manifest.txt` was attempted, but it currently fails
because multiple rows marked as expected eval failures now succeed. That is a
manifest freshness issue, not an assert regression.
