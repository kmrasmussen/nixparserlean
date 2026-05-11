# TICKET-0034: Quoted Inherit Names

## Problem
The external corpus has a `quoted-inherit-name` blocker around scoped inherit
forms such as `inherit (scope) "or"`. The parser currently consumes inherit
names as identifiers rather than the richer static attribute-name syntax.

## Goal
Parse static quoted inherit names and preserve existing inherit validation
semantics.

## In Scope
- Extend inherit name parsing to accept quoted static names.
- Add smoke fixtures for bare and scoped quoted inherit names.
- Ensure duplicate inherit validation includes quoted names.
- Update the external manifest row currently blocked by `quoted-inherit-name`.
- Document the supported inherit-name forms.

## Out of Scope
- Dynamic inherit names unless a real Nix syntax/design decision requires it.
- Evaluator support beyond behavior already covered by inherit fixtures.

## Acceptance Criteria
1. Smoke fixtures parse quoted inherit names.
2. Duplicate quoted/static inherit names are still validation failures.
3. The external `quoted-inherit-name` row advances to `pass` or a narrower
   blocker.
4. Default and external e2e manifests pass.
