# TICKET-0078: Local Pre-Push Gate

## Problem
The project relies on manual discipline to run local checks before pushing. The
workflow should make it easy to run the same gate locally that CI will run
remotely.

## Goal
Add a lightweight local pre-push/check script that runs the repository's
high-confidence gate and documents when to use it.

## In Scope
- Add a script such as `scripts/pre-push-check.sh`.
- Run `nix flake check` by default.
- Optionally expose focused modes for faster local iteration.
- Document the script in `roadmap/06-project-operations.md` or docs/testing.

## Out of Scope
- Automatically installing Git hooks.
- Blocking every commit.
- Running network-backed external corpus checks by default.

## Acceptance Criteria
1. A single local command runs the pre-push gate.
2. The command passes locally.
3. Docs tell contributors to run it before pushing.
4. The command matches or clearly supersets the GitHub Actions workflow.
