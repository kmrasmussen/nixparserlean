# TICKET-0079: CI Status And Required Checks Doc

## Problem
Even after CI exists, contributors need a clear project-level statement of
which checks are expected before pushing and which checks are optional or
network-backed.

## Goal
Document the CI/local gate contract and recommended branch protection settings.

## In Scope
- Document required local gate, remote CI gate, and optional external corpus
  gate.
- Explain why `nix flake check` omits incompatible systems unless explicitly
  run with all systems.
- Recommend GitHub branch protection / required status checks.
- Link to the pre-push script and CI workflow once they exist.

## Out of Scope
- Configuring GitHub repository settings directly.
- Multi-platform CI implementation.
- External corpus automation.

## Acceptance Criteria
1. Docs clearly name required, optional, and network-backed checks.
2. Branch protection recommendations are explicit.
3. The doc links to the local gate and GitHub workflow.
4. `git diff --check` passes.
