# Core Semantics Roadmap

The core language is the project's main proof target. It is currently useful,
but still too close to the surface language for the long-term goal.

## Current Core

Core currently keeps many surface-like forms:

- literals, paths, lists, attrsets;
- `letIn`, lambdas, control flow, `assert`, `with`;
- selection/defaults, `hasAttr`, application;
- unary and binary operators;
- static, inherit, and dynamic bindings.

This has been pragmatic because it lets evaluation grow quickly. The next
stage should decide which constructs are truly core and which should lower
away.

## Design Target

Core should become:

- small enough that core validation invariants are easy to state;
- explicit about effects and host boundaries;
- friendly to evaluation and preservation theorems;
- still close enough to Nix that debugging desugared output remains possible.

## Milestone A: Name The Minimal Core (complete)

`docs/core.md` now classifies current core forms as permanent values,
permanent computation, temporary surface forms, mostly-lowered forms, and
semantic-boundary forms.

The follow-up simplification tickets are:

- `TICKET-0039`: first core simplification slice;
- `TICKET-0040`: next core validation contract invariants.

The completed classification distinguishes:

- **surface forms retained temporarily**;
- **permanent core forms**;
- **forms that should lower away**;
- **forms that require a separate semantic decision**.

Candidate permanent core forms:

- primitive values;
- paths as inert values;
- lists and attrsets;
- static and dynamic bindings;
- lambda/application;
- selection;
- conditionals;
- a small operator set.

Candidate lowering targets:

- `inherit` is already mostly lowered.
- scoped inherit is already lowered to selection.
- selection defaults might lower into a smaller missing-value/conditional
  representation later.
- `with` may become an explicit environment operation rather than core syntax.

## Milestone B: First Core Simplification (started)

Static selection defaults now lower away for static non-empty paths: desugaring
uses `hasAttr` plus `select` inside `ifThenElse`, while dynamic-path defaults
retain the existing core select-default branch.

Follow-up simplifications remain:

- decide whether `with` lowers away or becomes a stable core environment rule;
- decide whether dynamic selection defaults need a no-duplication core helper;
- prove the static selection-default preservation claim named in
  `NixParserLean/Desugar.lean`.

Recommended next core ticket: make a `with` decision. Either keep it as a
permanent core environment form with a documented invariant, or lower it into a
smaller explicit environment operation before broader preservation proofs.

## Milestone C: Core Validation As A Contract

Core validation should stay even as proofs grow. Its role should become:

- executable contract for CLI/e2e;
- defense against desugar regressions;
- theorem target for preservation.

Current extra contract slice:

- static binding names must be non-empty before evaluation or proof work sees
  them.

Next invariants to consider:

- normalized static nested attrset shape after merge;
- dynamic path expressions are valid and side-effect-free;
- no unsupported dynamic bindings in recursive scopes before eval.

Acceptance criteria:

- Each new core invariant has one direct `core-fail` or desugar/eval fixture.
- Proofs can refer to the invariant predicate or helper, not reimplement it
  from scratch.

## Milestone D: Evaluator Coverage

The evaluator now covers a real fragment. The next semantic gains should be
chosen by whether they unlock real Nix patterns or proofs.

High-value additions:

1. Builtins as an explicit environment.
2. Imported functions or a host-aware value shape.
3. More exact string/path coercion policy.
4. Recursive update semantics if needed by corpus.
5. Better function value diagnostics and JSON representation.

Keep unsupported cases classified as `eval-fail`, not `other-fail`.

## Milestone E: Semantic Fuel

Entry-step fuel is now deterministic. The next step is proof structure:

- define a subset of expressions without thunks or host imports;
- prove monotonicity for literals and binary expressions; (landed for the
  total primitive literal/binary proof harness)
- widen to lists and non-recursive attrsets;
- later connect the evaluator to a small-step relation.

Do not widen the theorem target to closures, thunks, or host imports until the
small subset is clean.

## Milestone F: Examples As Regression Specs

The example suite has been split into focused examples for pure expressions,
recursion, lambdas, dynamic attributes, host boundary behavior, and a
proof-oriented static attrset fragment. Each example is referenced from the
relevant e2e manifest.

Future example work should follow the same pattern: add a small documented
example only when it clarifies a semantic boundary or regression behavior.
