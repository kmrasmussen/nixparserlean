# TICKET-0049: Host Effect Evaluator Shape

## Problem
The current host import lane resolves imports by evaluating imported files and
reifying representable values back into core syntax. This blocks imported
closures and may not scale to module-like patterns.

## Goal
Design the next host effect evaluator shape without changing pure evaluation.

## In Scope
- Compare value reification, host-aware evaluation, and effect-typed core
  designs.
- Identify the smallest implementation slice after imported-function
  diagnostics.
- Document tradeoffs in `roadmap/05-host-effects.md` or `docs/`.

## Out of Scope
- Implementing full host-aware evaluation.
- Search path implementation.

## Acceptance Criteria
1. Design document names the chosen next direction.
2. Pure `CoreEval` remains filesystem-free.
3. Follow-up implementation ticket is concrete.
