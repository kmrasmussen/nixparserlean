# TICKET-0019: Evaluator Semantic Precision — Equality and Interpolation Coercion

## Problem
Two evaluator behaviours simplify Nix's actual semantics in ways that are
not documented and not covered by fixtures:

1. **Cross-kind equality.** `CoreEval.beqValue` falls through to `false` for
   any unmatched constructor combination (`int == str`, closure-vs-closure,
   etc.). Real Nix raises a type error in some equality cases.
2. **String interpolation coercion.** `evalStringParts` only accepts
   `.str text` in the interpolated position. Real Nix coerces ints,
   paths, and a few other values into strings during interpolation.
   TICKET-0010 introduced text-only interpolation; coercion was deferred.

See `flagged.md` items #13 and #14.

## Goal
Pin down the evaluator's semantics for equality and string interpolation
to a documented, tested subset of Nix's behaviour.

## In Scope
- For equality: decide the policy (mirror Nix's type errors, keep the
  current `false`, or reject heterogeneous comparisons with `eval error:`)
  and apply it consistently to `==` and `!=`.
- For interpolation: extend coercion to a documented value subset
  (typically int, bool, null, path), keep the current explicit failure for
  attrsets/lists/closures, and decide what to do with floats once
  TICKET-0017 lands.
- Eval fixtures for each accepted/rejected value kind, including the
  current rejections so they keep failing for the documented reason.
- Update `docs/core.md` to describe both policies.

## Out of Scope
- `toString` builtin and string-context tracking.
- Derivation/path coercion that triggers store realisations.
- Hashing or comparison of closures by structure.

## Acceptance Criteria
1. Cross-kind `==` / `!=` behaviour is documented in `docs/core.md` and
   covered by at least two fixtures (one accepted, one rejected).
2. Interpolation coercion is documented and covered by fixtures for each
   accepted primitive kind plus at least one rejected aggregate kind.
3. The evaluator's behaviour matches the documented policy on every
   smoke and eval fixture.
4. The flake `checks.e2e-smoke` passes.
