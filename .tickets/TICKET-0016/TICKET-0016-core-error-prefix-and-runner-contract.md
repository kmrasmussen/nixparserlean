# TICKET-0016: Core Validation Error Prefix and Runner Contract

## Problem
`CoreValidate.lean` formats its failures with the prefix `core error:`. The
Rust e2e runner (`e2e/runner/src/main.rs`) only classifies stderr lines
starting with `parse error`, `semantic error`, or `eval error`; everything
else falls into `Outcome::OtherFail`.

There is no fixture that triggers core validation, so the inconsistency is
silent. The first time a real core-validation failure fires, it will be
reported as an "unexpected failure" with no possible manifest expectation
to match — and a contributor will have to re-derive the runner contract.

See `flagged.md` item #2.

## Goal
Establish a single, explicit contract for which error prefixes the runner
recognises, and align `CoreValidate.lean` (and any future Lean-side
diagnostics) with it.

## In Scope
- Decide between two options:
  - reuse `semantic error:` for core validation (treating core invariants
    as semantic), or
  - introduce a new prefix (`core error:`) plus a new manifest expectation
    (e.g. `core-fail`) in the Rust runner.
- Document the chosen contract in `docs/architecture.md` and
  `docs/testing.md`.
- Add at least one fixture that intentionally violates a core invariant
  (e.g. a hand-written test that constructs an invalid core expression
  through the existing CLI path) and have it match the chosen expectation.

## Out of Scope
- Structured parse errors (TICKET-0008).
- A generic diagnostic reporter that does not need string-prefix sniffing.

## Acceptance Criteria
1. Either every error path emits a prefix in
   `{parse error, semantic error, eval error}`, or the runner gains a new
   expectation key with documented semantics.
2. The decision is recorded in `docs/architecture.md` and
   `docs/testing.md`.
3. A fixture exercises core validation and matches its expectation.
4. The flake `checks.e2e-smoke` continues to pass on all four supported
   systems.
