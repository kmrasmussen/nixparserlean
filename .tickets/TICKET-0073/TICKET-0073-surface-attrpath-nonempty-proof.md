# TICKET-0073: Surface Attrpath Nonempty Proof

## Problem
Desugaring rejects empty static attrpaths, but parser-produced surface
attrpaths should make that branch unreachable. The cross-layer proof is still
missing.

## Goal
Prove a restricted theorem that parser/surface static attrpaths used in normal
bindings are non-empty before desugaring.

## In Scope
- Define the restricted surface attrpath subset.
- Prove or state a checked helper connecting the subset to non-empty core paths.
- Document excluded dynamic and quoted-interpolation cases.
- Update flagged/roadmap notes.

## Out of Scope
- Full parser correctness.
- Dynamic attrpath non-emptiness proof.
- Full desugar soundness.

## Acceptance Criteria
1. A checked theorem or helper captures the non-empty invariant for a useful
   restricted subset.
2. `lake build` passes.
3. Docs explain remaining proof gap.
4. The flagged caveat is narrowed if the theorem lands.
