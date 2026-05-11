# TICKET-0024: Parenthesized Application and Lambda Diagnostics

## Problem
The smoke parser accepts many Nix expression forms, but pinned nixpkgs files
still fail on common application shapes such as:

```nix
lib.makeExtensible (lib.extends f rattrs)
removeAttrs (import ./. { inherit system; }) [ "_type" ]
```

The immediate parser gap is that `parseApp` does not treat a parenthesized
expression as an application argument start. A second issue makes corpus
triage noisy: `parseLambda` is attempted speculatively, and failures while
parsing a valid lambda body can be backtracked into misleading errors at the
lambda header.

## Goal
Make common parenthesized application forms parse, and make external corpus
failures point at the real next unsupported construct.

## In Scope
- Add `(` as a valid application argument start.
- Add parser smoke fixtures for parenthesized function arguments, nested
  application, and parenthesized imports used as arguments.
- Improve lambda parsing/error handling enough that valid lambda headers are
  not reported as unsupported merely because the body contains a later parse
  failure.
- Re-run the pinned external manifest and update notes to describe the new
  first blockers.

## Out of Scope
- Full nixpkgs parsing.
- Evaluation of every newly parsed shape.
- A broad parser-combinator rewrite.

## Acceptance Criteria
1. `lib.makeExtensible (lib.extends f rattrs)` parses.
2. `removeAttrs (import ./. { inherit system; }) [ "_type" ]` parses.
3. A lambda with an unsupported body reports the body blocker rather than
   pretending the lambda header is unsupported.
4. `e2e/manifest.txt` contains focused parser fixtures for the new behavior.
5. `e2e/external-manifest.txt` expected-failure notes are refreshed after
   the parser change.
