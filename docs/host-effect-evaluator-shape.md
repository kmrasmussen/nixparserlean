# Host Effect Evaluator Shape

`--eval-imports` handles imports by resolving imported files in
`HostEval.lean`, evaluating each imported file to a `Core.Eval.Value`, and then
reifying representable values back into `Core.Expr` before the final pure
evaluation pass. That keeps `CoreEval` filesystem-free. Bare imported closures
still cannot be reified, but immediately applied imported closures can now run
inside the host import layer when their argument and result are representable.

## Chosen Direction

Keep pure `CoreEval` unchanged and add a host-aware import substitution layer as
the next implementation target.

The host layer still parses, validates, desugars, core-validates, and evaluates
imported files explicitly. Import replacement now has a first host-aware closure
application path for immediate applications. Pure evaluation remains available
for expressions with no host-only values; host evaluation owns the extra
capability.

## Options Compared

### Continue Value Reification

Pros:

- already implemented for ints, floats, strings, bools, null, paths, lists, and
  attrsets;
- keeps the final pass inside pure `CoreEval`;
- easy to test with the current import manifest.

Cons:

- closures cannot be represented without inventing a value expression form;
- repeated reification can hide the distinction between source syntax and
  runtime values;
- module-like imported functions stay blocked.

Use this as the compatibility path for values that already reify cleanly.

### Host-Aware Evaluation Layer

Pros:

- keeps filesystem access outside `CoreEval`;
- can thread imported closures as values rather than forcing them back into
  syntax;
- keeps normalized relative imports, configured angle search paths, and import
  recursion detection inside one explicit capability boundary.

Cons:

- needs a new value-slot or environment representation in `HostEval`;
- must define exactly where host values are allowed;
- requires focused e2e coverage for imported functions before widening.

This is the current direction. The first implementation slice supports
immediate imported-closure application while preserving bare imported-closure
rejection.

### Effect-Typed Core

Pros:

- could express import/path capabilities directly in the model;
- may become useful for proofs about host effects.

Cons:

- changes the shape of the core language too early;
- risks mixing host behavior into the pure proof surface;
- is larger than needed to unblock imported functions.

Defer this until the host-aware layer has clarified the real invariants.

## Landed First Slice

- `HostEval.lean` has a host-aware path for
  `(import ./function.nix) argument`.
- The imported file is still evaluated through the explicit host layer.
- The imported closure is applied in the host layer with a representable
  argument, and the result is reified back into core syntax.
- Bare imported closures still fail with
  `eval error: unsupported imported function values`.
- Filesystem behavior remains outside `CoreEval`.

Next widening targets:

- host-aware application where the argument depends on the importing
  expression's local environment;
- imported functions that return functions;
- a more explicit host value-slot representation if immediate application
  becomes too narrow.

## Non-Goals

- No implicit `NIX_PATH`.
- Configured angle search paths now have a separate first slice; this design
  still excludes ambient `NIX_PATH` and system `<nixpkgs>` discovery.
- No network fetchers or store realization.
- No pure evaluator filesystem access.
