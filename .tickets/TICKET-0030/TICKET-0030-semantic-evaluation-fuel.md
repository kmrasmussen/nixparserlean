# TICKET-0030: Semantic Evaluation Fuel

## Problem
Evaluation fuel is configurable and tested, but it currently behaves mainly
as a thunk-forcing limit. That is enough to prevent runaway recursion, but it
is not yet a semantic step budget that can support monotonicity or
determinism statements.

## Goal
Redesign evaluator fuel as an explicit semantic budget for supported core
evaluation steps.

## In Scope
- Define what one fuel step means for the current evaluator.
- Make recursive calls consume fuel consistently enough to state useful
  monotonicity expectations.
- Keep cycle detection diagnostics stable.
- Add fixtures that distinguish ordinary evaluation budget exhaustion from
  recursive binding cycles.
- Document the relationship between fuel, laziness, and thunk forcing.

## Out of Scope
- Proving termination of arbitrary Nix evaluation.
- A full small-step semantics in the first implementation slice.
- Performance optimization.

## Acceptance Criteria
1. Fuel consumption is documented as a semantic policy rather than an
   implementation accident.
2. `--fuel` behavior remains deterministic across repeated runs.
3. Existing recursive-cycle fixtures still fail with cycle diagnostics rather
   than generic fuel exhaustion where appropriate.
4. New e2e fixtures cover budget exhaustion for non-trivial successful and
   failing expressions.
5. The roadmap identifies the next theorem target after semantic fuel lands.

## Plan
1. Define one fuel step as entering `Core.Eval.eval` for a core expression.
2. Spend fuel at that entry point, while structural list/binding/parameter
   walkers spend fuel only when they evaluate contained expressions.
3. Remove the separate thunk-force decrement so thunk forcing uses the same
   expression-entry budget.
4. Add low-fuel manifests that pin down failure, success, and deterministic
   repeated runs for a non-trivial expression.
5. Update docs and the roadmap with the next monotonicity theorem target.

## Resolution
Fuel now has an explicit entry-step policy. Every call to `Core.Eval.eval`
spends one step before inspecting the expression constructor. Structural
walkers do not spend fuel by themselves; they pass the current budget to the
contained expressions they evaluate. Thunk forcing no longer decrements fuel
separately, so recursive bindings use the same expression evaluation budget as
the rest of the evaluator.

The low-fuel e2e coverage now distinguishes:

- fuel `0`: evaluation fails before entering the expression;
- fuel `1`: `1 + 2` fails after entering the binary expression but before its
  operands can evaluate;
- fuel `2`: `1 + 2` succeeds, and repeated manifest entries exercise
  deterministic behavior.

Existing recursive cycle fixtures remain in the eval manifest, where the
default budget is sufficient to reach the cycle checks and report recursive
binding diagnostics.

The roadmap now names the next theorem target: monotonicity for literals and
binary expressions under the entry-step policy.

Verification:

```text
lake build: pass
e2e/manifest.txt: 36 passed, 3 expected parse failures, 8 expected validation failures
e2e/eval-manifest.txt: 41 passed, 20 expected eval failures
e2e/fuel-manifest.txt: 1 expected eval failure
e2e/fuel-low-manifest.txt: 2 expected eval failures
e2e/fuel-success-manifest.txt: 2 passed
nix flake check: pass on x86_64-linux
```
