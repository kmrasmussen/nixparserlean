# TICKET-0023: Host Import IO Layer

## Problem
TICKET-0005 makes import rejection explicit, but real import evaluation needs a
host IO boundary rather than pure `CoreEval` pretending filesystem access is a
normal expression.

## Goal
Design and implement the first host-side import evaluator path.

## In Scope
- Decide where source file base directories live.
- Parse imported files through the existing parser/validator/desugar pipeline.
- Keep pure core evaluation separate from host IO orchestration.
- Add local import fixtures that evaluate successfully.

## Out of Scope
- Network fetchers.
- Store path realisation.
- Full Nix path canonicalisation.

## Acceptance Criteria
1. A local `import ./file.nix` fixture evaluates successfully through an
   explicit IO-aware path.
2. Pure `CoreEval` remains usable without filesystem access.
3. Unsupported import/path cases still emit classified `eval error:` messages.
