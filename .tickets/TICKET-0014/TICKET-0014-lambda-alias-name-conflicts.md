# TICKET-0014: Lambda Alias Name vs. Parameter Entry Validation

## Problem
Real Nix rejects `args@{ args, ... }: ...` because the alias name collides
with one of the destructured parameters. Our surface validator only checks
duplicates *within* a `ParamSet`'s entries (`Validate.validateParamEntries`
via `Validate.validateLambdaParam`); it never compares the alias name with
those entries.

At runtime, `CoreEval.bindParam` for `LambdaParam.alias name (.attrset ps)`
binds the alias first and then layers the parameter set on top through
`bindParamSet`, so the alias is silently shadowed instead of producing an
error.

See `flagged.md` item #4.

## Goal
Reject lambda parameters whose alias name collides with one of the
destructured entry names at validation time, with a clear `semantic error:`.

## In Scope
- Extend `Validate.validateLambdaParam` (or a new helper) to detect alias /
  entry name collisions for both `name@{ ... }` and `{ ... }@name` shapes.
- Mirror the check in `CoreValidate.validateLambdaParam` so the invariant
  also holds against direct core construction.
- Surface fixtures: `validation-fail` cases for both alias positions.

## Out of Scope
- Cross-binding name collisions (e.g. `let x = 1; in x@{x}: ...`).
- Renaming any existing AST constructor.

## Acceptance Criteria
1. `args@{ args, ... }: args` fails surface validation with
   `semantic error: ...`.
2. `{ args, ... }@args: args` fails surface validation the same way.
3. Existing `aliased-param-lambda.nix`, `reverse-aliased-param-lambda.nix`,
   and `aliased-default-param-lambda.nix` still pass.
4. Each rejection has a fixture in `e2e/manifest.txt` with `validation-fail`.
