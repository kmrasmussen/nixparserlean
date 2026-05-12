# TICKET-0053: Fuel-Bound ParseAdd And ParseMul Loops

## Problem
The expression parser is still the largest `partial` island. The documented
termination strategy chooses explicit parser fuel first, but no expression
operator level has been converted yet.

## Goal
Convert the additive and multiplicative expression parser loops to total
fuel-bounded helpers while keeping public parser signatures stable.

## In Scope
- Add internal `parseAddLoopFuel` and `parseMulLoopFuel` helpers in
  `NixParserLean/Parser.lean`.
- Size each loop fuel from `ParserState.remaining.length`.
- Keep `parseAdd` and `parseMul` public behavior unchanged.
- Preserve existing parse output and source-position diagnostics.
- Update parser/partial-fuel docs.

## Out of Scope
- Full expression parser conversion.
- Parser-combinator replacement.
- User-facing parser fuel CLI flags.
- Changes to lambda, list, attrset, selection, or application parsing unless
  needed to keep behavior stable.

## Acceptance Criteria
1. `parseAdd` and `parseMul` no longer contain local partial loops.
2. Existing parser failure offsets remain stable.
3. Default parser manifest passes.
4. External parser manifest passes.
5. `lake build` passes.
