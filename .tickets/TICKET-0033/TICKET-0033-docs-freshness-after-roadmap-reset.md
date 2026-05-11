# TICKET-0033: Docs Freshness After Roadmap Reset

## Problem
Some documentation predates the latest path, fuel, validator, and roadmap
work. In particular, docs can still describe path values or test coverage in
ways that are weaker than the current code and flake checks.

## Goal
Refresh the high-traffic docs so they match the actual code, manifests, and
roadmap.

## In Scope
- Audit and update `docs/core.md`, `docs/testing.md`,
  `docs/import-and-path-boundary.md`, `docs/partial-and-fuel.md`,
  `docs/README.md`, and `flagged.md`.
- Update `AGENTS.md` if its verification checklist under-runs current e2e
  coverage.
- Link caveats to the new root `roadmap/` files or concrete tickets.
- Add a short blog note if the refresh changes project guidance.

## Out of Scope
- Parser or evaluator behavior changes.
- Large rewrites of architecture docs not needed for freshness.

## Acceptance Criteria
1. Docs no longer claim path values are unsupported.
2. Testing docs reflect all flake-check manifests, including fuel/JSON/import.
3. `AGENTS.md` either names `nix flake check` or delegates to `docs/testing.md`.
4. `flagged.md` points active caveats at roadmap files or tickets.
5. `git diff --check` passes; no Lean build is required unless code changes.
