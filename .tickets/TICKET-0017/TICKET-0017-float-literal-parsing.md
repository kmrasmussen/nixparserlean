# TICKET-0017: Float Literal Parsing

## Problem
`Parser.Basic.integer` only consumes digit characters. There is no float
lexer. `1.5` is read as `1` followed by `.`, at which point `parseSelect`
calls `parseAttrPath` → `attrName` → `ident`, which rejects the digit `5`
("expected identifier"). So float literals fail with a parse error
mid-tree.

Real Nix files contain floats (`1.0`, `3.14`, `1e6`, scientific notation),
and there is no manifest entry recording this gap.

See `flagged.md` item #9.

## Goal
Parse Nix float literals into the AST and decide their first-pass eval
semantics.

## In Scope
- A float literal lexer that recognises `digits . digits`, optional
  exponent (`eN`, `e+N`, `e-N`), and rejects ambiguous shapes that conflict
  with attribute selection (e.g. `1.foo` should still be a select on the
  integer `1`, not a float).
- A new `Expr.float` constructor (or a typed `Number` ADT) and a
  corresponding `Core.Expr` form.
- Surface and eval fixtures for representative float literals.
- Decide whether the evaluator handles `+`, `-`, `*`, `/` over floats now
  or rejects them with an explicit `eval error:`.

## Out of Scope
- IEEE-754 semantics proofs.
- Mixed int/float coercion rules beyond a documented choice.
- Hex/octal/binary integer literals (separate gap if it surfaces).

## Acceptance Criteria
1. `1.0`, `3.14`, `1e6`, `2.5e-3` all parse to a float AST node.
2. `pkgs.foo` and `1.bar` (selection on an integer attribute name, if
   supported) keep their existing parse behaviour or fail with a clear
   parse error.
3. Eval support for floats either lands in this ticket with arithmetic
   tests, or is deferred with an explicit `eval-fail` fixture and a
   follow-up ticket.
4. `docs/parser.md` and `docs/ast.md` describe the float form.
