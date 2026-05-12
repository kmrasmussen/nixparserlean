# TICKET-0058: String Scanner Totality

## Problem
Quoted and indented string scanners are still `partial`, even though string
parsing now carries important interpolation and escape behavior.

## Goal
Convert quoted and indented string scanning to total fuel-bounded helpers while
preserving interpolation, escape handling, and source positions.

## In Scope
- Add total fuel-bounded helpers for quoted string scanning.
- Add total fuel-bounded helpers for indented string scanning.
- Preserve current interpolation and escaped indented interpolation behavior.
- Add or update focused string fixtures if needed.
- Update parser/partial-fuel docs.

## Out of Scope
- Implementing the full Nix string escape matrix.
- Expression parser totality.
- Changing evaluator string coercion.

## Acceptance Criteria
1. Targeted string scanner loops no longer use `partial def`.
2. `lake build` passes.
3. Default parser manifest passes.
4. External parser manifest passes.
5. String/interpolation docs remain accurate.
