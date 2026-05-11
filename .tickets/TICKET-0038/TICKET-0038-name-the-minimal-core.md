# TICKET-0038: Name the Minimal Core

## Problem
The current core language remains close to surface syntax. That is pragmatic
for evaluation, but it makes proof targets broader than they need to be.

## Goal
Document the intended minimal core and classify current core constructors as
permanent, temporary, or undecided.

## In Scope
- Update `docs/core.md` with a minimal-core classification.
- Identify one or more forms that should lower away in later tickets.
- Add roadmap links from `roadmap/03-core-semantics.md`.
- Open narrower follow-up tickets if needed.

## Out of Scope
- Changing core syntax in this ticket.
- Proving preservation.

## Acceptance Criteria
1. `docs/core.md` clearly distinguishes permanent core forms from temporary
   retained surface forms.
2. At least one concrete simplification follow-up is identified.
3. No behavior changes are made.
4. `git diff --check` passes.
