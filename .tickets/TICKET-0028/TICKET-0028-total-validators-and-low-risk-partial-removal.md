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
