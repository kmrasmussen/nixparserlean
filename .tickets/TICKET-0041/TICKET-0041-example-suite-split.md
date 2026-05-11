# TICKET-0041: Example Suite Split

## Problem
`examples/current-core-showcase/showcase.nix` is useful but dense. Separate
examples would make supported behavior and regression intent easier to read.

## Goal
Split the current showcase into a small suite of focused examples that remain
covered by e2e manifests.

## In Scope
- Add examples for pure expressions, recursion, lambdas, dynamic attrs, host
  boundary, and proof-oriented static attrsets.
- Reference each example from the appropriate manifest.
- Keep the existing showcase or retire it with a clear note.
- Update example README files.

## Out of Scope
- New language semantics.

## Acceptance Criteria
1. Each example has explanatory markdown.
2. Each example is exercised by an e2e manifest.
3. `nix flake check` passes.
