# TICKET-0052: Host Value Slots For Imported Closures

## Problem
`--eval-imports` currently evaluates imported files and reifies representable
values back into core syntax. Imported closures are rejected because they cannot
be reified, which blocks module-like patterns where an imported file returns a
function.

## Goal
Let the host import lane carry imported closure values far enough for the
importing file to apply them, without adding filesystem behavior to `CoreEval`.

## In Scope
- Add an internal host value slot or host environment representation in
  `HostEval.lean`.
- Keep current reification for representable imported values.
- Add a repo-local fixture where an imported function is applied through
  `--eval-imports`.
- Preserve or narrow the existing imported-function rejection fixture.
- Update host-effect docs and roadmap notes.

## Out of Scope
- Filesystem IO in `CoreEval`.
- Angle search paths.
- Store realization, network fetchers, or module-system semantics.
- Full lazy import semantics.

## Acceptance Criteria
1. A repo-local imported-function application passes through `--eval-imports`.
2. Existing representable imported values still pass.
3. `CoreEval.lean` remains filesystem-free.
4. The import manifest classifies any remaining imported-function limitation
   precisely.
5. `lake build`, the import manifest, and the eval manifest pass.
