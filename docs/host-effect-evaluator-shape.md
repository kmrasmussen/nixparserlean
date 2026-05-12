# Host Effect Evaluator Shape

`--eval-imports` currently handles imports by resolving imported files in
`HostEval.lean`, evaluating each imported file to a `Core.Eval.Value`, and then
reifying representable values back into `Core.Expr` before the final pure
evaluation pass. That keeps `CoreEval` filesystem-free, but it cannot represent
imported closures.

## Chosen Direction

Keep pure `CoreEval` unchanged and add a host-aware import substitution layer as
the next implementation target.

The host layer should still parse, validate, desugar, core-validate, and
evaluate imported files explicitly. The difference is that import replacement
should eventually be able to carry a host value slot for imported values that
cannot be reified as core syntax, especially closures. Pure evaluation remains
available for expressions with no host slots; host evaluation owns the extra
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
- gives angle search paths, normalized imports, and import recursion detection
  one explicit capability boundary.

Cons:

- needs a new value-slot or environment representation in `HostEval`;
- must define exactly where host values are allowed;
- requires focused e2e coverage for imported functions before widening.

This is the recommended next direction.

### Effect-Typed Core

Pros:

- could express import/path capabilities directly in the model;
- may become useful for proofs about host effects.

Cons:

- changes the shape of the core language too early;
- risks mixing host behavior into the pure proof surface;
- is larger than needed to unblock imported functions.

Defer this until the host-aware layer has clarified the real invariants.

## Smallest Implementation Slice

Draft follow-up ticket:

**Host Value Slots For Imported Closures**

- Add an internal host expression or environment slot in `HostEval.lean` for
  imported values that cannot be reified.
- Use it only inside `--eval-imports`; do not add filesystem behavior to
  `CoreEval`.
- Keep current reification for representable values.
- Add one repo-local fixture where an imported function is applied by the
  importing file.
- Preserve the existing imported-function rejection fixture until the new path
  is implemented, then move it to the success manifest row with a clear note.

## Non-Goals

- No implicit `NIX_PATH`.
- No angle search-path implementation in this slice.
- No network fetchers or store realization.
- No pure evaluator filesystem access.
