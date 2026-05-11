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

## Plan
1. Convert the surface validator mutual block to total definitions with an
   explicit validation fuel argument.
2. Convert the core validator mutual block with the same shape and layer
   specific fuel-exhaustion prefix.
3. Keep the public `validate` APIs unchanged by using a large internal default
   fuel.
4. Run parser, desugar, core-validation, and eval manifests to verify behavior
   and classifications are unchanged.
5. Update docs and the project log with the remaining proof refinement.

## Resolution
`Validate.lean` and `CoreValidate.lean` no longer use `partial`. Both validator
mutual blocks are now total fuel-bounded walks. Recursive descent through an
expression, string part list, lambda parameter, parameter default list,
attribute path, or binding list receives a smaller validation fuel value.
Empty lists validate at any fuel.

The public APIs remain:

```lean
NixParserLean.validate
NixParserLean.Core.validate
```

Those wrappers use `defaultValidationFuel = 100000`, so the fuel is an
internal termination device rather than a CLI-visible behavior. If exhausted,
the diagnostics keep the same layer prefixes:

```text
semantic error: validation fuel exhausted
core error: validation fuel exhausted
```

The remaining proof refinement is replacing this conservative fuel with a
structural measure over the AST once that proof effort is worth the extra
complexity.

Verification:

```text
lake build: pass
no `partial def` remains in `Validate.lean` or `CoreValidate.lean`
e2e/manifest.txt: 36 passed, 3 expected parse failures, 8 expected validation failures
e2e/core-validation-manifest.txt: 1 expected core failure
e2e/desugar-manifest.txt: 6 passed, 1 expected validation failure
e2e/eval-manifest.txt: 41 passed, 20 expected eval failures
nix flake check: pass on x86_64-linux
```
