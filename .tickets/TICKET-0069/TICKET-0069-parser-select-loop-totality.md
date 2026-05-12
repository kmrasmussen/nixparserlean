# TICKET-0069: Parser Select Loop Totality

## Problem
Selection parsing has already carried important ambiguity fixes around dynamic
selection and path arguments, but its local loop is still part of the parser
`partial` cluster.

## Goal
Convert the selection loop to a total fuel-bounded helper while preserving the
selection/path disambiguation behavior.

## In Scope
- Add a `parseSelectLoopFuel`-style helper.
- Preserve adjacent selection and spaced dynamic selection behavior.
- Preserve path argument parsing such as `fileContents ./.version`.
- Add focused fixtures if needed.
- Update parser totality docs.

## Out of Scope
- Full expression parser conversion.
- Changing selection grammar.
- Angle path import behavior.

## Acceptance Criteria
1. The `parseSelect` local loop is total/fuel-bounded.
2. Default parser manifest passes.
3. External manifest passes.
4. Selection/path ambiguity fixtures still pass.
5. `lake build` passes.
