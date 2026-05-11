# TICKET-0047: Relative Import Normalization Policy

## Problem
Host imports join base directory and relative path text, but do not normalize
aliases such as `./a/../x.nix`. That can affect recursion detection and error
clarity.

## Goal
Define and test the normalization policy for host imports while keeping pure
path values inert.

## In Scope
- Decide whether normalization applies to recursion detection, file reads, or
  both.
- Add host import fixtures for simple relative path aliases.
- Preserve pure `Value.path` text behavior.
- Document the policy.

## Out of Scope
- Symlink resolution unless explicitly chosen.
- Store path realization.

## Acceptance Criteria
1. Relative import alias behavior is documented and tested.
2. Recursive import detection is robust for the selected policy or the
   limitation is explicit.
3. Pure path value e2e fixtures still preserve parsed text.
