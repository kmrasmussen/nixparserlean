# TICKET-0015: Duplicate Binding Detection Across Static and Dynamic Forms

## Problem
Two related gaps mean that "duplicate" bindings can slip through every layer:

1. `Validate.pathsConflict` only fires when *both* paths are fully static.
   So `{ a = 1; ${"a"} = 2; }` and `{ ${k} = 1; ${k} = 2; }` pass surface
   validation.
2. `Desugar.mergeBindingInto` only merges `staticAssign` against
   `staticAssign`. Two `dynamicAssign`s that resolve to the same key, or a
   static binding and a dynamic binding at the same level, are passed
   through as separate bindings.

At evaluation time, `CoreEval.evalBindingInto` calls `insertAttr` /
`insertPathAttr`, which silently overwrite by name. The user sees
last-binding-wins semantics with no error from any pass.

Real Nix raises a duplicate-attribute error at evaluation time when two
keys collide, regardless of which form produced them.

See `flagged.md` items #5 and #6.

## Goal
Detect duplicate keys produced by mixed static/dynamic bindings, at the
latest possible pass that has the information available, with a clear
`eval error:` (or earlier where statically decidable).

## In Scope
- Eval-time check in `evalBindingInto` (or a wrapper) that detects an
  already-present name being re-bound and fails explicitly.
- Decide whether the same check belongs in `Desugar.mergeBindings` for
  cases where both keys are statically known after lowering, and whether
  to emit a `semantic error:` then.
- Eval fixtures for: static + duplicate-static (already covered),
  static + dynamic-of-same-name, dynamic + dynamic-of-same-name, and at
  least one nested-prefix collision (`{ a.b = 1; a = { b = 2; }; }`).

## Out of Scope
- A general theory of attribute-set merging.
- Preserving the source position of the offending binding (covered by
  TICKET-0008 once structured errors land).

## Acceptance Criteria
1. `{ a = 1; ${"a"} = 2; }` fails with a clear duplicate-binding error
   under `--eval`.
2. `{ ${k} = 1; ${k} = 2; }` (with `k` evaluating to a fixed string) fails
   the same way.
3. Mixed prefix conflicts that desugar to overlapping nested attrsets are
   either rejected at desugar time or fail at eval time.
4. The error message uses an existing prefix (`semantic error:` or
   `eval error:`) the runner already classifies — see TICKET-0016.
5. At least three new fixtures cover these cases.
