# TICKET-0081: Split Fuel Proof Module

## Problem
The evaluator module now carries both production evaluation code and the growing
fuel proof harness. Each proof-ticket edit makes the large evaluator boundary
feel slower than it needs to be.

## Goal
Move the restricted fuel proof harness out of `NixParserLean/CoreEval.lean`
into a child proof module while preserving theorem names and runtime behavior.

## In Scope
- Add a `NixParserLean.CoreEval.Fuel` module for the current restricted fuel
  harnesses.
- Keep theorem names in the `NixParserLean.Core.Eval` namespace.
- Keep `NixParserLean/CoreEval.lean` focused on runtime evaluator definitions.
- Update roadmap and fuel docs to identify the new proof module.
- Verify with `lake build`.

## Out of Scope
- New fuel theorems.
- Production evaluator behavior changes.
- Parser or CLI behavior changes.
- Full build-system redesign.

## Acceptance Criteria
1. Existing fuel theorem names still build from the public library import path.
2. Runtime evaluator modules no longer contain the restricted fuel proof
   harness.
3. `lake build` passes.
4. Docs explain why the split helps future proof-ticket iteration.

## Resolution

Moved the restricted evaluator fuel proof harness from
`NixParserLean/CoreEval.lean` into `NixParserLean/CoreEval/Fuel.lean`.

The moved names remain in the `NixParserLean.Core.Eval` namespace, including:

- `evalLiteralBinarySubsetWithFuel_monotone`
- `evalLiteralUnaryBinarySubsetWithFuel_monotone`
- `evalLiteralUnaryBinaryListItemsWithFuel_monotone`
- `evalNonrecursiveStaticAttrsetWithFuel_monotone`

`NixParserLean.lean` now imports `NixParserLean.CoreEval.Fuel`, so the public
library root still exposes the checked proof harness while runtime modules such
as `HostEval` can continue importing only `CoreEval`.

Verification:

- `nix develop -c lake build`
