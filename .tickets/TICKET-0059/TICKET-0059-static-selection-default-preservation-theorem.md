# TICKET-0059: Static Selection Default Preservation Theorem

## Problem
Static selection defaults now lower through `hasAttr` and `select` in
`ifThenElse`, but the preservation claim is only recorded as a TODO theorem.

## Goal
Prove a focused theorem about the static selection-default lowering shape or
its evaluator behavior for a restricted static subset.

## In Scope
- Add a checked theorem in `NixParserLean/Desugar.lean` or a nearby proof file.
- Keep the theorem restriction explicit.
- Cover static non-empty paths only.
- Update core/desugar proof docs.

## Out of Scope
- Dynamic selection defaults.
- Full desugar semantic preservation.
- Host imports, thunks, or recursive attrsets.

## Acceptance Criteria
1. A theorem names the static selection-default restriction.
2. `lake build` passes.
3. Desugar manifest passes.
4. Docs explain what the theorem does not prove.
