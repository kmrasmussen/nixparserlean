# TICKET-0026: Evaluate the Parsed Operator Surface

## Problem
The parser recognizes a broad operator table, but evaluation still supports
only a smaller subset. Parsed operators such as list concatenation, attrset
update, comparisons, and float arithmetic are either unsupported or only
partially represented in `CoreEval`.

## Goal
Close the gap between parsed operator syntax and evaluator behavior for the
ordinary pure operators that do not require host IO or derivation semantics.

## In Scope
- Evaluate list concatenation with `++`.
- Evaluate attrset update with `//` for shallow attrset merges.
- Evaluate numeric comparisons over supported numeric values.
- Evaluate float arithmetic and mixed int/float arithmetic with a documented
  representation policy.
- Add focused `eval-*.nix` fixtures for pass and failure cases.
- Update `docs/core.md` and expected-failure manifests.

## Out of Scope
- String context semantics.
- Derivations and store path behavior.
- Recursive update operators not present in Nix's ordinary `//` semantics.
- Arbitrary precision numeric formalization beyond the current Lean model.

## Acceptance Criteria
1. `++` evaluates for lists and rejects incompatible operands with
   `eval error:`.
2. `//` evaluates for attrsets and rejects incompatible operands with
   `eval error:`.
3. `<`, `>`, `<=`, and `>=` evaluate for supported numeric values.
4. Float arithmetic fixtures that are currently expected eval failures are
   either moved to pass or have more precise unsupported notes.
5. The evaluator documentation names the exact supported operator matrix.

## Resolution
Implemented evaluation for the pure parsed operators that were still missing:

- list concatenation with `++`
- shallow attrset update with `//`
- numeric comparisons over ints, floats, and mixed int/float operands
- float arithmetic and mixed int/float arithmetic

Integer-only arithmetic still returns integer values. Any arithmetic involving
a float computes with Lean `Float` and returns a float value formatted with
`Float.toString`.

Added eval fixtures for list concatenation, attrset update, numeric
comparisons, float arithmetic, mixed numeric arithmetic, operator type errors,
and float division by zero. Updated `docs/core.md` with the supported operator
matrix and float policy.

Verification:

```text
lake build: pass
eval e2e: 39 passed, 20 expected eval failures, 0 unexpected failures, 0 unexpected successes
```
