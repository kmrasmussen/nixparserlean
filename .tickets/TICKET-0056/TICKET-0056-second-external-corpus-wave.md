# TICKET-0056: Second External Corpus Wave

## Problem
The first pinned external nixpkgs corpus set is green, but it is still small
relative to real Nix usage. The next parser/evaluator work should be driven by
new pinned blockers rather than guesses.

## Goal
Add a second immutable external corpus wave and classify any new failures into
actionable blocker categories.

## In Scope
- Add a small batch of immutable nixpkgs URL rows to
  `e2e/external-manifest.txt`.
- Use stable cache names and optional `sha256` comments where useful.
- Classify rows as `pass`, `parse-fail`, `validation-fail`, `core-fail`, or
  `eval-fail`.
- Use `./e2e/external-summary.sh` to summarize blocker categories.
- Update parser/corpus docs and create follow-up ticket candidates from any
  new blocker categories.

## Out of Scope
- Making network-backed external runs part of ordinary `nix flake check`.
- Large unreviewable corpus imports.
- Fixing every blocker discovered by the new corpus wave in the same ticket.

## Acceptance Criteria
1. The external manifest has a second pinned corpus wave.
2. Any non-pass rows have notes specific enough to become follow-up tickets.
3. `./e2e/external-summary.sh` reflects the new corpus state.
4. External manifest run passes according to expected classifications.
5. Ordinary flake checks remain network-free.
