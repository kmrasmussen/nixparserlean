# TICKET-0077: GitHub Actions Flake Check CI

## Problem
The repository has a strong local `nix flake check` gate but no checked-in
GitHub Actions workflow. A branch can be pushed without the repository itself
declaring the CI contract that should run remotely.

## Goal
Add a GitHub Actions workflow that runs the same high-confidence flake gate used
locally.

## In Scope
- Add `.github/workflows/ci.yml`.
- Install or enable Nix on GitHub-hosted Linux runners.
- Run `nix flake check`.
- Document omitted incompatible systems if the workflow only checks
  `x86_64-linux`.
- Keep network-backed external corpus checks out of ordinary CI.

## Out of Scope
- Full multi-platform CI.
- Running external network corpus checks by default.
- Release automation.

## Acceptance Criteria
1. `.github/workflows/ci.yml` runs `nix flake check` on pull requests and pushes.
2. CI docs explain what the workflow covers and does not cover.
3. Local `nix flake check` passes before commit.
4. The workflow does not require external corpus network access.
