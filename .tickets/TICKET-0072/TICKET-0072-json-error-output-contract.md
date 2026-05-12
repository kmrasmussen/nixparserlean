# TICKET-0072: JSON Error Output Contract

## Problem
JSON output is covered for successful cases, but error output has no stable
machine-readable contract.

## Goal
Define and test how parse, validation, core, and eval failures should appear in
JSON mode.

## In Scope
- Decide JSON fields for error layer, message, and source position when
  available.
- Add focused JSON e2e rows for at least parse, validation, and eval errors.
- Keep text stderr behavior stable unless intentionally changed.
- Update CLI/testing docs.

## Out of Scope
- Rich diagnostic rendering.
- LSP/editor integration.
- Full structured parse error recovery.

## Acceptance Criteria
1. JSON error contract is documented.
2. JSON manifest covers representative failure layers.
3. Existing text-mode manifests still pass.
4. `nix flake check` passes if flake JSON checks change.
