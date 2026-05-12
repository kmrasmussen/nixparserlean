# TICKET-0067: External Corpus Lane Split Design

## Problem
The external manifest currently exercises parser/surface validation behavior.
As the corpus grows, parser, desugar, eval, and import expectations may need
separate external lanes.

## Goal
Design whether and how to split external corpus manifests into focused lanes
without making network-backed checks part of ordinary flake verification.

## In Scope
- Compare a single manifest with per-mode manifests.
- Decide naming and cache policy for future lanes.
- Document how expected failures should be classified across lanes.
- Add follow-up implementation tickets if needed.

## Out of Scope
- Adding a large new corpus wave.
- Making external checks mandatory in `nix flake check`.
- Rewriting the Rust runner.

## Acceptance Criteria
1. A design note or roadmap section names the chosen lane strategy.
2. The strategy preserves network-free ordinary checks.
3. Follow-up tickets are concrete if implementation is needed.
4. `./e2e/external-summary.sh` remains accurate for the current manifest.
