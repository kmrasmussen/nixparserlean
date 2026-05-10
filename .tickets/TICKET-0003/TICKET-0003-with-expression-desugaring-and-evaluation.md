# TICKET-0003: With Expression Desugaring and Evaluation

## Problem
`with` parses and validates but remains unsupported in core evaluation.
Nix code uses `with pkgs; ...` frequently.

## Goal
Define a conservative core/eval semantics for `with`.

## In Scope
- Static attrset scopes.
- Name lookup fallback through the `with` scope.
- Clear shadowing rules between lexical env and with scope.
- Eval fixtures for simple and shadowed lookups.

## Out of Scope
- Dynamic scope objects beyond evaluated attrsets.
- Proof of lookup equivalence.

## Acceptance Criteria
1. `with { x = 1; }; x` evaluates to `1`.
2. Lexical shadowing behavior is documented and tested.
3. Non-attrset `with` scope fails with `eval error:`.
