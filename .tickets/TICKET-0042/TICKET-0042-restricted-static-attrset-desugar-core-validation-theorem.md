# TICKET-0042: Restricted Static Attrset Desugar-Core-Validation Theorem

## Problem
Desugaring has focused lemmas, but there is not yet a checked theorem that a
surface-valid subset desugars into core-valid output.

## Goal
Prove the first restricted surface-validation to core-validation theorem for
static attrsets.

## In Scope
- Define a restricted static-attrset subset with no dynamic paths.
- Prove that successful desugaring of that subset preserves the relevant core
  validation invariant.
- Keep theorem assumptions explicit in the name or docstring.
- Add documentation explaining what the theorem excludes.

## Out of Scope
- Full language soundness.
- Evaluator preservation.
- Dynamic attributes.

## Acceptance Criteria
1. At least one theorem is checked by `lake build`.
2. The theorem connects surface validation/desugaring to core validation or a
   core validation helper.
3. Exclusions are documented.
4. Existing desugar and eval manifests pass.
