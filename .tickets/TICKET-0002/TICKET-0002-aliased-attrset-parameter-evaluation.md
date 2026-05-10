# TICKET-0002: Aliased Attrset Parameter Evaluation

## Problem
The evaluator supports identifier parameters and attrset destructuring, but
aliases such as `args@{ a, ... }:` and `{ a, ... }@args:` still fail.

## Goal
Bind aliases during function application while preserving existing destructuring
behavior.

## In Scope
- Alias binding for attrset parameters.
- Both alias syntaxes already represented by the AST.
- Eval fixtures for alias plus required fields, ellipsis, and defaults.

## Out of Scope
- Aliasing non-attrset parameters beyond the surface shapes already parsed.
- Changing parser representation.

## Acceptance Criteria
1. `args@{ a, ... }: args.a + a` evaluates for a matching attrset.
2. Defaults and required fields still behave as currently tested.
3. Unsupported alias cases remain explicit `eval error`s.
