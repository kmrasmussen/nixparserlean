# TICKET-0062: List Fuel Monotonicity

## Problem
Fuel monotonicity is only proven for primitive literals and primitive-literal
binary expressions. Lists are the next useful structural subset.

## Goal
Prove monotonicity for lists whose elements are already in the restricted
primitive expression subset.

## In Scope
- Extend or add a total proof harness for primitive-list evaluation.
- Prove extra fuel preserves successful list results.
- Keep the theorem restriction explicit.
- Update proof/fuel docs.

## Out of Scope
- Lists containing thunks, closures, host imports, selection, or recursive
  attrsets.
- Full evaluator monotonicity.
- Small-step semantics.

## Acceptance Criteria
1. A checked theorem states list monotonicity for the restricted subset.
2. `lake build` passes.
3. Fuel manifests pass.
4. Eval manifest passes.
5. Docs name the next widening target.

## Resolution

Added a total list-item proof harness in `NixParserLean/CoreEval.lean`:

- `evalLiteralUnaryBinaryListItemsWithFuel`
- `LiteralUnaryBinaryListItemsSubset`
- `evalLiteralUnaryBinarySubsetWithFuel_of_subset`
- `evalLiteralUnaryBinaryListItemsWithFuel_of_subset`
- `evalLiteralUnaryBinaryListItemsWithFuel_monotone`

The theorem is intentionally restricted to lists whose elements are already in
the literal/unary/binary proof subset. It excludes closures, thunks, host
imports, selection, conditionals, attrsets, and recursive evaluation.

Updated proof/fuel roadmap docs to name non-recursive static attrsets as the
next widening target.

Verification:

- `nix develop -c lake build`
- `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/fuel-manifest.txt --parser "lake exe nixparserlean --eval --fuel 0 --file"`
- `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/fuel-low-manifest.txt --parser "lake exe nixparserlean --eval --fuel 1 --file"`
- `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/fuel-success-manifest.txt --parser "lake exe nixparserlean --eval --fuel 2 --file"`
- `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/fuel-high-manifest.txt --parser "lake exe nixparserlean --eval --fuel 5 --file"`
- `nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/eval-manifest.txt --parser "lake exe nixparserlean --eval --file"`
