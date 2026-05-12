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
