# TICKET-0031: Total Validator Mutual Recursion

## Problem
`TICKET-0028` removed `partial` from low-risk evaluator helpers, but the
surface and core validator mutual blocks still need an explicit termination
story.

An attempted direct conversion from `partial def` to `def` failed because Lean
cannot infer a shared decreasing measure through derived substructure lists:

- surface validation calls `validateExprs path.exprs`
- core validation calls through `paramSet.entries`

The recursive calls are structurally reasonable, but not visible enough to the
termination checker in the current shape.

## Goal
Make `Validate.lean` and `CoreValidate.lean` total, or land the smallest
supporting structure needed for Lean to check their termination.

## In Scope
- Introduce direct attr-path and parameter-set validator helpers if that makes
  substructure recursion visible.
- Alternatively, add explicit `termination_by` measures for the validator
  mutual blocks.
- Keep diagnostics and validation behavior unchanged.
- Run parser, desugar, core-validation, and eval manifests after the change.

## Out of Scope
- Parser termination.
- Evaluator semantic fuel.
- Desugaring soundness theorems.

## Acceptance Criteria
1. `Validate.lean` validator recursion no longer uses `partial`, or the file
   has a strictly smaller remaining partial island with a documented reason.
2. `CoreValidate.lean` validator recursion no longer uses `partial`, or the
   file has a strictly smaller remaining partial island with a documented
   reason.
3. Validation diagnostics and e2e classifications are unchanged.
4. `docs/partial-and-fuel.md` and the roadmap are updated with the final
   termination shape.
