# TICKET-0037: External Corpus Infrastructure Next Layer

## Problem
The external corpus manifest is useful but still minimal. It lacks content
hashes, a first-class blocker summary command, and a refresh workflow.

## Goal
Make external corpus maintenance easier without making network access part of
ordinary flake checks.

## In Scope
- Add a small script or documented command for blocker summaries.
- Decide and document a hash/provenance format for URL rows.
- Optionally add hash checking to the Rust runner if the format is small.
- Keep cached external runs separate from `nix flake check`.

## Out of Scope
- Large CI integration.
- Automatic network refresh in default checks.

## Acceptance Criteria
1. A maintained command or script summarizes external blocker categories.
2. Corpus provenance/hash policy is documented.
3. Existing external manifest behavior remains compatible.
4. Rust runner changes, if any, are covered by e2e runner verification.
