# TICKET-0044: Parser Lexer Helper Totality

## Problem
Parser termination is large and invasive. The lowest-risk starting point is
the lexer-level helper cluster rather than the full expression parser.

## Goal
Remove or reduce `partial` from parser basic lexing helpers.

## In Scope
- Target helpers such as `takeWhileGo`, comment skipping, angle path scanning,
  and string scanning helpers if feasible.
- Use explicit fuel or structural recursion where Lean accepts it.
- Preserve source offsets, line, and column behavior exactly.
- Add parser fixtures if behavior is touched.

## Out of Scope
- Full expression parser termination.
- Parser-combinator rewrites.

## Acceptance Criteria
1. At least one parser helper `partial` island is removed or narrowed.
2. Parse-error position fixtures remain stable.
3. Default and external parser manifests pass.
4. Termination approach is documented.
