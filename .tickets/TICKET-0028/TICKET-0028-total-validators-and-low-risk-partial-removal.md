# TICKET-0028: Total Validators and Low-Risk Partial Removal

## Problem
The roadmap for proof-oriented work identifies broad `partial` debt. Some of
that debt is high-risk parser/evaluator work, but the validators and simple
list walkers are structurally recursive and are good first targets for Lean
checked termination.

## Goal
Remove `partial` from the low-risk validation/list-walking layer and document
the termination shape used.

## In Scope
- Convert simple list walkers named in `docs/roadmap/partial-and-fuel/` to
  total definitions where Lean accepts them directly.
- Convert surface validator recursion in `Validate.lean` to total definitions,
  or isolate the smallest remaining obstacle.
- Convert core validator recursion in `CoreValidate.lean` to total definitions,
  or isolate the smallest remaining obstacle.
- Keep behavior unchanged and covered by the existing manifests.
- Add a blog note explaining the termination argument and any remaining
  blockers.

## Out of Scope
- Parser termination.
- Evaluator semantic fuel.
- Major AST redesign unless required and documented separately.

## Acceptance Criteria
1. At least the low-risk list walkers in `Validate.lean`, `CoreValidate.lean`,
   and `CoreEval.lean` no longer use `partial`.
2. The validator mutual recursion is either total or has a precise follow-up
   ticket explaining the remaining Lean termination obstacle.
3. `lake build` and the relevant e2e manifests pass.
4. `docs/partial-and-fuel.md` and the roadmap status are updated.

## Plan
1. Remove `partial` from the low-risk evaluator list and equality helpers that
   Lean can check directly.
2. Confirm the validation-side list walkers are already total, then attempt the
   broader validator mutual blocks.
3. If Lean rejects the validator mutual blocks, document the precise
   termination obstacle and open a focused follow-up ticket.
4. Use the existing behavior-preserving e2e manifests because this ticket is a
   totality refactor, not a language semantics change.
5. Update the partial/fuel docs, write the project log note, then commit and
   push the completed chunk.

## Resolution
Removed `partial` from the low-risk evaluator helpers:

- `beqValue`, `beqValues`, `beqAttrs`
- `equalValue`, `equalValues`, `equalAttrs`
- `paramEntryNames`, `containsName`, `findExtraAttr?`

The parameter helper definitions were moved out of the large partial evaluator
mutual block so Lean can check them independently.

The validation-side duplicate/conflict list walkers were already total. I
also attempted to make the surface and core validator mutual blocks total.
Lean rejected both for the same precise reason: it cannot infer a shared
decreasing measure through derived substructure lists such as surface
`path.exprs` and core `paramSet.entries`. That obstacle is now documented in
`docs/partial-and-fuel.md` and the partial/fuel roadmap. The precise follow-up
ticket is `TICKET-0031`.

Verification:

```text
lake build: pass
e2e/manifest.txt: 36 passed, 3 expected parse failures, 8 expected validation failures
e2e/core-validation-manifest.txt: 1 expected core failure
e2e/eval-manifest.txt: 39 passed, 20 expected eval failures
e2e/desugar-manifest.txt: 5 passed, 1 expected validation failure
e2e/fuel-manifest.txt: 1 expected eval failure
```
