# TICKET-0025: External Corpus Ratchet

## Problem
The project has a pinned external manifest, but it is still tiny and outside
the default smoke loop. It is useful for orientation, but not yet a strong
ratchet for real Nix coverage.

## Goal
Turn the external corpus into a small, curated, reproducible signal that
guides parser and semantic work without making ordinary development noisy.

## In Scope
- Expand `e2e/external-manifest.txt` from the current handful of nixpkgs
  files to a curated set of roughly 15-25 pinned files.
- Record expectations by layer: `parse-fail`, `validation-fail`, `core-fail`,
  or `eval-fail`, with notes that name the first known blocker.
- Add a short corpus report mode or documented command that summarizes
  failures by blocker category.
- Keep network access optional by relying on the existing cache behavior.
- Document when to update expectations after parser/evaluator improvements.

## Out of Scope
- Running the external corpus in the default flake check.
- Large-scale nixpkgs snapshot traversal.
- License/provenance automation beyond clear pinned URLs and cache names.

## Acceptance Criteria
1. The external manifest contains a broader curated sample of real Nix files.
2. Every expected failure note identifies a specific next blocker.
3. Running the external manifest produces zero unexpected failures.
4. Documentation explains how to refresh, cache, and interpret the corpus.
5. At least one blocker category is represented by multiple files, so future
   syntax work can be prioritized by observed frequency.
