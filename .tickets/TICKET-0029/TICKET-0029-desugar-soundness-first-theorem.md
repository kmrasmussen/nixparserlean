# TICKET-0029: Desugar Soundness First Theorem

## Problem
The project now has surface validation, desugaring, and core validation, but
the relationship between those layers is still enforced only by tests. The
mission calls for Lean to prove that the model's phases preserve useful
invariants.

## Goal
State and prove the first useful theorem connecting surface validation,
desugaring, and core validation.

## In Scope
- Choose a small theorem statement that can land incrementally, such as:
  "for this restricted class of surface expressions, successful desugaring
  produces core that passes core validation."
- Start with static attrsets and inherit lowering if the full language is too
  large.
- Replace the empty-path fallback in desugaring with an impossible input,
  explicit error, or supporting lemma.
- Add theorem-oriented helper definitions only where they reduce proof
  complexity.
- Document what the theorem does and does not cover.

## Out of Scope
- Full semantic preservation of evaluation.
- Parser correctness.
- Total parser termination.

## Acceptance Criteria
1. At least one checked theorem relates desugaring output to a core invariant.
2. The theorem covers a real desugaring behavior already used by fixtures,
   not a toy duplicate of existing code.
3. The unreachable empty-path fallback in `Desugar.bindingFromPath` is removed,
   rejected explicitly, or justified by a checked lemma.
4. `lake build` passes with the theorem enabled.
5. A blog note explains why this is the first proof target and what remains.

## Plan
1. Keep the first theorem narrow: static attrpath lowering exposes the
   top-level static core binding name that core validation reasons about.
2. Change `bindingFromPath` to return `Except` so the empty static path case is
   rejected explicitly instead of constructing invalid core.
3. Preserve existing desugaring behavior for static and dynamic attribute
   paths.
4. Add focused desugar e2e coverage for the unchanged static attrset path.
5. Document what this proof slice covers and what remains.

## Resolution
`Desugar.bindingFromPath` now returns `Except String Core.Binding`. Fully static
non-empty paths still lower to nested static core assignments, and dynamic paths
still lower to `dynamicAssign`. The old empty-path fallback is gone; if a
statically empty path reaches desugaring, it now fails with:

```text
desugar error: empty attribute path
```

The checked theorem `bindingFromPath_static_top_name` now states that when
`staticNames?` sees a non-empty static path, successful desugaring exposes the
same top-level static core binding name. That is the core-side name invariant
used by later static binding validation. `bindingFromPath_static_nested_tail`
continues to cover the nested static attrset shape, and
`bindingFromPath_empty_static_rejected` records the explicit empty-path
rejection.

This is not full surface-to-core validation preservation yet. It is the first
small proof slice tying real static attrpath desugaring to a core invariant.

Verification:

```text
lake build: pass
e2e/manifest.txt: 36 passed, 3 expected parse failures, 8 expected validation failures
e2e/desugar-manifest.txt: 6 passed, 1 expected validation failure
nix flake check: pass on x86_64-linux
```
