# TICKET-0004: Dynamic Attribute Evaluation

## Problem
Dynamic attribute names are represented in the AST and core, but evaluation
rejects dynamic bindings and dynamic paths.

## Goal
Evaluate a first text-only/interpolated dynamic attribute fragment.

## In Scope
- Evaluate dynamic path parts to strings.
- Dynamic attrset bindings in non-recursive attrsets.
- Dynamic selection paths.
- Eval fixtures for `${key}` and `"prefix-${key}"`.

## Out of Scope
- Dynamic recursive attrsets.
- Full string coercion semantics.
- Paths/imports in string interpolation.

## Acceptance Criteria
1. `{ ${key} = 1; }` evaluates when `key` is a text string.
2. `attrs.${key}` selects the resulting attribute.
3. Unsupported interpolation values fail explicitly.
