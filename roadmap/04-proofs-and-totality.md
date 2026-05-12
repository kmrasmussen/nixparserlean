# Proofs And Totality Roadmap

The proof program should proceed from cheap structural facts to semantic
theorems. Avoid trying to prove "Nix correctness" all at once.

## Current Proof Assets

Already present:

- static attrpath top-level binding theorem;
- nested static attrpath shape theorem;
- empty static path rejection theorem;
- merge helper theorems for static binding names;
- total low-risk evaluator helpers;
- total fuel-bounded surface and core validators;
- deterministic entry-step evaluator fuel policy.

Remaining broad `partial` islands:

- parser and lexer helpers;
- surface-to-core desugaring walk;
- host import resolution/reification walk;
- evaluator and related environment/thunk functions.

## Milestone A: Restricted Desugar Soundness

First serious theorem target:

```text
For a restricted static-attrset surface subset:
if surface validation succeeds and desugaring succeeds,
then core validation succeeds.
```

Restriction should be explicit:

- no dynamic attr paths;
- no string interpolation inside attr names;
- no lambdas initially;
- static attrsets, literals, lists, and simple `let` only.

Why this target:

- It connects the existing validator/desugar/core-validator layers.
- It uses real behavior already covered by fixtures.
- It creates a path from runtime backstop to checked invariant.

Acceptance criteria:

- The theorem is checked by `lake build`.
- The theorem name includes the restriction.
- A doc note explains exactly what is excluded.

## Milestone B: Remove Desugar Walk `partial` (complete as fuel-bounded defs)

Approach:

1. Copy the successful validator strategy first: explicit desugar fuel.
2. Keep public `desugar` API unchanged.
3. Preserve current diagnostics.
4. Once stable, decide whether structural recursion is worth proving.

Why fuel first:

- The walk is mutually recursive over surface syntax and derived lists.
- Fuel removes opacity immediately and can be refined later.
- It makes downstream proofs about "fuel sufficient" possible.

Acceptance criteria:

- No `partial def` remains in the main desugar walk.
- Existing desugar/eval manifests pass.
- `docs/partial-and-fuel.md` records the shape.

Landed shape:

- the public `desugar` API is unchanged;
- the internal walk uses `defaultDesugarFuel = 100000`;
- `exprFuel`, `bindingFuel`, `stringPartsFuel`, attrpath helpers,
  lambda-parameter helpers, and list walkers are total definitions;
- fuel exhaustion reports `desugar error: fuel exhausted`.

## Milestone C: Parser Termination Strategy

Parser termination should come after external corpus blockers are reduced.

Recommended path:

1. Convert lexer-level helpers first:
   - `takeWhileGo` (complete as an input-length fuel wrapper);
   - comment skipping;
   - angle path scanning (complete as an input-length fuel wrapper);
   - string scanning.
2. Convert expression parser levels with explicit fuel, starting with local
   additive and multiplicative operator loops.
3. Revisit `decreasing_by` on input length after the fuel-bounded shape is
   stable.
4. Preserve source positions exactly.

The full strategy is documented in
`docs/parser-expression-termination-strategy.md`.

Do not rewrite the parser into a combinator library unless the handwritten
parser becomes unmaintainable.

## Milestone D: Fuel Monotonicity

Initial theorem target:

```text
If eval fuel expr = ok value for literal/binary subset,
then eval (fuel + extra) expr = ok value.
```

Landed first slice: `evalLiteralBinarySubsetWithFuel_monotone` proves this for
the total literal/binary proof harness in `CoreEval.lean`. The subset includes
primitive literals and binary expressions whose operands are primitive literals.

Start with:

- literals; (landed)
- binary operators over primitive values; (landed for primitive literal operands)
- unary operators.

Then widen to:

- lists;
- non-recursive attrsets;
- selection;
- conditionals.

Do not include recursive thunks until the environment model is proof-friendly.

## Milestone E: Determinism

The evaluator is written as a deterministic function, but checked determinism
still matters once fuel and environment behavior grow.

First theorem:

```text
If eval fuel expr = ok v1 and eval fuel expr = ok v2, then v1 = v2.
```

This may be trivial by rewriting for the current functional evaluator, but it
becomes more useful if a small-step relation is introduced later.

## Milestone F: Preservation

Longer-term theorem:

```text
If Core.validate expr = ok () and eval fuel expr = ok value,
then value satisfies a corresponding value invariant.
```

This requires defining value invariants first. Do not start here.
