# TICKET-0055: Relative Import Path Normalization Policy

## Problem
`--eval-imports` joins relative import path text with the importing file's
directory. The host filesystem may resolve aliases such as `./nested/../x.nix`
for reads, but recursion detection and diagnostics do not yet have a clear
normalization policy.

## Goal
Decide and test how the host import lane handles relative import aliases,
especially for recursive import detection, while keeping pure path values as
inert text.

## In Scope
- Document whether normalization applies to recursion detection, file reads,
  both, or neither.
- Add repo-local fixtures around `./nested/../file.nix` style aliases.
- Add a recursive import alias fixture or a documented expected failure.
- Keep pure `Core.Eval.Value.path` text unnormalized.
- Update import/path boundary docs and host-effects roadmap.

## Out of Scope
- Store path canonicalization.
- Symlink policy beyond a documented first decision.
- Angle search paths.
- Changes to pure path value semantics.

## Acceptance Criteria
1. The normalization policy is documented.
2. Alias import behavior is covered in the import manifest.
3. Recursive import alias behavior is covered as pass or expected eval-fail.
4. Pure path-value behavior is unchanged.
5. Import manifest passes.
