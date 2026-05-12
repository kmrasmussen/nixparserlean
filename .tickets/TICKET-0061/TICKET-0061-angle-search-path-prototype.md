# TICKET-0061: Angle Search Path Prototype

## Problem
Angle paths parse as path literals and are rejected in import position. The
search-path design now exists, but there is no implementation.

## Goal
Implement explicit repo-local angle import resolution through a repeatable
`--search-path NAME=PATH` host option.

## In Scope
- Add CLI parsing for repeatable `--search-path NAME=PATH`.
- Thread the mapping through the host import lane.
- Resolve `<name>` and `<name/rest>` from the explicit mapping.
- Add repo-local search-root fixtures.
- Preserve no-search-path angle rejection.

## Out of Scope
- Implicit `NIX_PATH`.
- Network fetchers.
- Store realization.
- Pure evaluator filesystem behavior.

## Acceptance Criteria
1. A repo-local angle import succeeds with explicit `--search-path`.
2. The existing no-search-path rejection remains tested.
3. Import manifest passes.
4. Help output documents the new option.
5. `CoreEval.lean` remains filesystem-free.
