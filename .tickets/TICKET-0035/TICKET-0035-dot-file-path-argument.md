# TICKET-0035: Dot-File Path Argument

## Problem
The external corpus has a `path-argument-dot-file` blocker around expressions
like `fileContents ./.version`. The parser supports relative path literals,
but application and selection/path disambiguation need a focused check for
dot-file arguments.

## Goal
Ensure `./.name` path literals work as application arguments without
regressing selection parsing.

## In Scope
- Add smoke fixtures for function application with `./.version`-style paths.
- Diagnose whether the blocker is path lexing, app stop logic, or surrounding
  external syntax.
- Update `e2e/external-manifest.txt` for the current blocker.
- Document any parser boundary change.

## Out of Scope
- Host file reads or import semantics.
- General path normalization.

## Acceptance Criteria
1. `fileContents ./.version` parses as application to a path literal.
2. Existing selection, import, and path fixtures still pass.
3. The external blocker advances to `pass` or a narrower note.
4. Default and external e2e manifests pass.
