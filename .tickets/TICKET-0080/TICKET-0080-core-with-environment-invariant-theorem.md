# TICKET-0080: Core `with` Environment Invariant Theorem

## Problem
`with` is now documented as permanent core syntax, but the lexical-first
environment invariant is not checked by Lean.

## Goal
State and prove a focused theorem for a restricted pure subset showing that
`withExpr scope body` appends scope attributes as fallback names without
overriding existing lexical bindings.

## In Scope
- Add a theorem in `NixParserLean/CoreEval.lean` or a nearby proof file.
- Restrict the theorem to a small environment/value subset.
- Cover the lexical-first lookup behavior used by `with`.
- Update core/proof docs.

## Out of Scope
- Full evaluator preservation.
- Recursive thunks and cycle behavior.
- Host imports.
- Replacing `with` with another core form.

## Acceptance Criteria
1. A theorem names the `with` lexical-first restriction.
2. `lake build` passes.
3. Eval manifest passes if evaluator helpers change.
4. Docs connect the theorem to the permanent-core `with` decision.
