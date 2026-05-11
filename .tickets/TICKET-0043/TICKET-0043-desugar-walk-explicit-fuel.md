# TICKET-0043: Desugar Walk Explicit Fuel

## Problem
The main surface-to-core desugaring walk still uses `partial`. The validators
show that explicit fuel can remove broad partial islands while preserving the
public API.

## Goal
Convert the recursive desugaring walk to total fuel-bounded definitions.

## In Scope
- Add internal desugar fuel to `expr`, `binding`, `stringParts`, attrpath, and
  parameter helpers.
- Preserve public `desugar` API and existing diagnostics.
- Keep total merge helpers unchanged unless needed.
- Update `docs/partial-and-fuel.md` and roadmap notes.

## Out of Scope
- Parser termination.
- Core simplification.

## Acceptance Criteria
1. The main desugar walk no longer uses `partial`.
2. Existing desugar/eval manifests pass.
3. Docs record the termination shape and remaining desugar proof work.
