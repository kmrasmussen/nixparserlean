# TICKET-0048: Angle Path Search Path Design

## Problem
Angle paths parse as path literals and are rejected as imports. Supporting
`<nixpkgs>`-style imports requires an explicit host search-path design.

## Goal
Design, and optionally prototype, a repo-local search-path mechanism that does
not depend on the user's machine.

## In Scope
- Document search-path semantics and CLI/config shape.
- Decide how search roots are supplied for tests.
- Add design fixtures if a prototype is included.
- Keep default behavior rejecting angle imports.

## Out of Scope
- Implicit system `NIX_PATH`.
- Network fetchers.
- Store realization.

## Acceptance Criteria
1. A design note states how angle imports would be resolved.
2. Current angle import rejection remains tested unless implementation lands.
3. Any prototype uses repo-local deterministic fixtures.
