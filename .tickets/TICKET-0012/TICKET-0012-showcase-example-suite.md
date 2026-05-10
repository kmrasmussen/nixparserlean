# TICKET-0012: Showcase Example Suite

## Problem
The smoke fixtures prove individual parser and evaluator features, but the
project does not yet have a human-facing example that shows the strongest
current end-to-end behavior.

## Goal
Add an `examples/` showcase with explanatory markdown and include its Nix file
in the e2e eval suite.

## In Scope
- One focused example subdirectory under `examples/`.
- A markdown explanation of what the example demonstrates.
- A `.nix` file that combines multiple supported language features.
- Eval e2e manifest coverage for the same `.nix` file.

## Out of Scope
- Golden output assertions in the e2e runner.
- A large gallery of examples.
- Unsupported Nix features such as imports or full string coercion.

## Acceptance Criteria
1. The example evaluates successfully through `--eval`.
2. The example is included in the e2e eval manifest.
3. The markdown explains which language features are being demonstrated.
