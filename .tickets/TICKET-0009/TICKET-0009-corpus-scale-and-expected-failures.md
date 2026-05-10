# TICKET-0009: Corpus Scale and Expected Failures

## Problem
The e2e harness supports manifests and URL caching, but the project needs a
larger, curated real-world corpus with clear expected-failure tracking.

## Goal
Grow corpus coverage without making CI noisy.

## In Scope
- Add representative external fixtures or pinned URLs.
- Categorize expected failures by missing syntax or semantics.
- Improve notes so recurring syntax gaps are visible.

## Out of Scope
- Large unpinned dependency snapshots.
- Treating every real-world failure as a regression.

## Acceptance Criteria
1. External corpus entries exist with stable names and expectations.
2. Expected failures have actionable notes.
3. The runner summary remains concise.
