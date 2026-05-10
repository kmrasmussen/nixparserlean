# TICKET-0010: String Interpolation and Coercion Semantics

## Problem
String interpolation parses and desugars, but evaluation only supports
text-only strings.

## Goal
Evaluate a first principled string interpolation fragment.

## In Scope
- Interpolate strings, ints, bools, and null if the chosen semantics allows it.
- Decide how attrsets and paths fail or coerce.
- Eval fixtures for supported and unsupported interpolations.

## Out of Scope
- Full Nix `toString` semantics.
- Derivation/string context tracking.

## Acceptance Criteria
1. Text interpolation with supported primitive values evaluates.
2. Unsupported interpolation values fail explicitly.
3. The chosen coercion rules are documented.
