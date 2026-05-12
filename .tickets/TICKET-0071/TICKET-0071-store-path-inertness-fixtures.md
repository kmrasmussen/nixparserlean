# TICKET-0071: Store Path Inertness Fixtures

## Problem
The roadmap says store-like paths are inert values, but the fixtures should
make that boundary hard to regress.

## Goal
Add focused fixtures and docs proving `/nix/store/...`-looking paths are inert
path values in pure evaluation and unsupported in host import position.

## In Scope
- Add pure eval fixture for store-like path values.
- Add or sharpen import eval-fail fixture for store-like imports.
- Update import/path boundary docs if needed.
- Keep behavior strictly non-realizing.

## Out of Scope
- Store realization.
- Copying paths to the Nix store.
- String context semantics.
- Existence checks.

## Acceptance Criteria
1. Pure store-like path value fixture passes.
2. Store-like import remains expected eval-fail.
3. Eval and import manifests pass.
4. Docs state that no realization or existence check occurs.
