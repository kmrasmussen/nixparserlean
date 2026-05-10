# TICKET-0013: Bare `inherit` Lowering in Recursive Scopes

## Problem
`Desugar.inheritBindings` lowers `inherit x;` to a core `staticAssign "x"
(.ident "x")`. Inside any recursive scope (`let`, `rec { ... }`), the new
binding shadows the enclosing `x` before the right-hand side is forced, so
the lookup self-references and the cycle detector in `CoreEval.lookupName`
fires with `eval error: recursive let binding 'x'`.

In Nix, bare `inherit` is meant to copy a name from the *enclosing* scope.
The current lowering is only sound in non-recursive contexts. There is no
fixture exercising bare `inherit name;` inside a recursive scope, so the
gap is invisible to CI.

See `flagged.md` item #1.

## Goal
Make bare `inherit name;` evaluate correctly when used inside `let` and
`rec { ... }` by sourcing the inherited values from the enclosing
environment instead of the recursive one.

## In Scope
- A correct lowering for bare `inherit` in recursive scopes — e.g. introduce
  a fresh non-shadowed name forwarder, or a new core form that evaluates
  against the outer env, or perform the substitution before building the
  recursive thunks.
- Eval fixtures for bare `inherit name;` inside `let` and `rec { ... }` that
  reference an outer binding (currently broken) and inside non-recursive
  attribute sets (currently working).
- Keep `inherit (scope) name;` behaviour unchanged — its lowering to
  `name = scope.name` already evaluates `scope` against the outer env.

## Out of Scope
- Reworking the surface AST representation of `inherit`.
- Source-preserving inherit groups in core output.
- Optimising the lowering for large `inherit` lists.

## Acceptance Criteria
1. `let x = 1; in let inherit x; in x` evaluates to `1`.
2. `let x = 1; in rec { inherit x; y = x + 1; }.y` evaluates to `2`.
3. Existing `inherit-from.nix` and other inherit fixtures still pass.
4. New eval fixtures cover bare `inherit` in both `let` and `rec` and are
   listed in `e2e/eval-manifest.txt` as `pass`.
