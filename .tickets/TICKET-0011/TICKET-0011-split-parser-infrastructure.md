# TICKET-0011: Split Parser Infrastructure

## Problem
`NixParserLean/Parser.lean` has grown past 700 lines and mixes low-level parser
state/token machinery with the expression grammar. That is still workable, but
it will make structured parse errors and larger grammar coverage harder to
review.

## Goal
Move reusable parser infrastructure into a dedicated module without changing
parser behavior.

## In Scope
- New parser infrastructure module for parser state, `ParserM`, whitespace,
  token, identifier, integer, and path literal helpers.
- Keep expression/string/attrset grammar in `Parser.lean`.
- Preserve the public `NixParserLean.parse` entry point.
- Full build, e2e, and flake verification.

## Out of Scope
- Structured parse error implementation.
- Parser grammar changes.
- Renaming AST constructors or changing parse output.

## Acceptance Criteria
1. `Parser.lean` imports the infrastructure module and shrinks.
2. Existing parser, desugar, and eval e2e manifests still pass.
3. The ticket leaves a blog note explaining the maintainability boundary.
