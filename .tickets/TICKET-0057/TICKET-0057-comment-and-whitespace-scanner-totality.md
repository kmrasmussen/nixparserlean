# TICKET-0057: Comment And Whitespace Scanner Totality

## Problem
`skipLineComment`, `skipBlockComment`, and `skipSpace` remain parser `partial`
helpers. They are low-level enough to convert before the larger expression
parser cluster.

## Goal
Move comment and whitespace scanning to total input-length fuel helpers without
changing parser behavior or source positions.

## In Scope
- Add fuel-bounded helpers in `NixParserLean/Parser/Basic.lean`.
- Keep public helper call sites stable where practical.
- Preserve line/column tracking through comments and whitespace.
- Add focused parser fixtures if any edge case is not already covered.
- Update `docs/partial-and-fuel.md`.

## Out of Scope
- Expression parser conversion.
- String scanner conversion.
- Parser-combinator replacement.

## Acceptance Criteria
1. The targeted comment/whitespace helpers no longer use `partial def`.
2. `lake build` passes.
3. Default parser manifest passes.
4. Existing parse error offsets remain stable.
5. Docs record the termination shape.
