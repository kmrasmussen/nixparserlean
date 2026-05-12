# Partial Definitions and Fuel

This inventory records why `partial` remains in the codebase and where it is
intentional debt.

## Parser

`Parser.lean` and `Parser/Basic.lean` still use recursive-descent functions
marked `partial`. The grammar is mutually recursive and backtracking-oriented,
so this is acceptable for now, but structured termination or parser fuel would
eventually make the parser model more proof-friendly.

The first lexer helpers have moved off `partial`:

- `takeWhileGo` delegates to `takeWhileGoFuel`, sized from remaining input;
- `anglePathGo` delegates to `anglePathGoFuel`, also sized from remaining
  input.
- line-comment, block-comment, and whitespace scanning delegate to
  `skipLineCommentFuel`, `skipBlockCommentFuel`, and `skipSpaceFuel`, each
  sized from the remaining input at the public wrapper.
- quoted and indented string scanning delegate to `quotedStringGoFuel` and
  `indentedStringGoFuel`, with the expression parser passed explicitly for
  interpolation.
- the additive and multiplicative expression loops delegate to
  `parseAddLoopFuel` and `parseMulLoopFuel`, sized from the remaining input
  after the left operand is parsed.

Both wrappers preserve the existing public helper shape and source-position
behavior. The remaining parser helper debt is now concentrated in the larger
expression parser cluster and list/binding-style parser loops.
The expression parser strategy is documented in
`parser-expression-termination-strategy.md`: use explicit parser fuel first,
starting with local operator loops, then consider `decreasing_by` refinements
after the fuel-bounded shape is stable.

## Validation

`Validate.lean` and `CoreValidate.lean` now use total fuel-bounded validator
walks. Each recursive descent through expressions, string parts, lambda
parameters, parameter defaults, attribute paths, and bindings receives a
smaller validation fuel value. Empty lists can validate at any fuel, while a
non-empty structure at fuel `0` fails with the same layer prefix:

```text
semantic error: validation fuel exhausted
core error: validation fuel exhausted
```

The public `validate` functions use `defaultValidationFuel = 100000`, so the
fuel is a termination device for the checker rather than a user-facing CLI
knob. The next proof-oriented improvement is replacing this conservative fuel
with structural termination proofs over the AST, but the broad validator
`partial` islands are gone.

## Desugaring

The simple attrpath helpers are now total definitions:

- `staticNames?`
- `nestedStaticAssign`
- `bindingFromPath`
- `inheritBindings`
- `inheritFromBindings`
- `mergeStaticAttrsets`
- `mergeBindingInto`
- `mergeBindings`

The merge helpers are total through an explicit internal fuel bound. The main
surface-to-core walk is also total now: `exprFuel`, `bindingFuel`,
`stringPartsFuel`, attrpath helpers, lambda-parameter helpers, and list walkers
all receive a decreasing desugar fuel. The public `desugar` API still uses
`defaultDesugarFuel = 100000`, so fuel is an internal termination device rather
than a user-facing knob.

Exhausting the budget fails with:

```text
desugar error: fuel exhausted
```

The remaining proof work is no longer blocked by an opaque `partial` desugar
walk; the next step is proving enough fuel for restricted surface subsets, then
replacing fuel with structural recursion where that becomes worth the effort.

## Evaluation

Evaluation remains `partial` and fuelled. Fuel is now a deterministic
core-expression evaluation budget: every entry into `Core.Eval.eval` consumes
one fuel step before inspecting the expression constructor. Structural list,
binding, and parameter walkers do not spend fuel by themselves; they spend
fuel when they evaluate contained expressions. Thunk forcing no longer has a
separate counter rule, because forcing a thunk evaluates its stored expression
through the same `eval` entry point.

Exhausting the budget fails with:

```text
eval error: evaluation fuel exhausted
```

The default remains `200`. The CLI exposes `--fuel N` for `--eval` so this
boundary can be tested directly. For example, `1 + 2` needs fuel two: the
binary expression consumes one step, then each literal operand sees one
remaining step.
Recursive binding cycles still report cycle diagnostics when the budget is
sufficient to reach the recursive force.

The checked fuel theorems are deliberately restricted. They live in
`NixParserLean.CoreEval.Fuel` under the `NixParserLean.Core.Eval` namespace, so
runtime evaluator imports can stay focused on `NixParserLean.CoreEval` while
proof-ticket edits target the child module. `evalLiteralBinarySubsetWithFuel_monotone`
proves that the total proof harness for primitive literals and binary
expressions over primitive literal operands preserves a successful result when
extra fuel is added. `evalLiteralUnaryBinarySubsetWithFuel_monotone` widens that
harness with unary expressions over primitive literals.
`evalLiteralUnaryBinaryListItemsWithFuel_monotone` adds the first recursive
walker theorem for lists whose items are in the same literal/unary/binary
subset. `evalNonrecursiveStaticAttrsetWithFuel_monotone` adds the next
restricted binding-structure theorem for non-recursive static attrsets whose
values are in that same subset. This still excludes closures, thunks, host
imports, dynamic bindings, inherited bindings, selection, conditionals, and
recursive attrsets.

The same module also carries first determinism checks for those harnesses:
`evalLiteralBinarySubsetWithFuel_deterministic`,
`evalLiteralUnaryBinarySubsetWithFuel_deterministic`,
`evalLiteralUnaryBinaryListItemsWithFuel_deterministic`,
`evalNonrecursiveStaticAttrBindingsWithFuel_deterministic`, and
`evalNonrecursiveStaticAttrsetWithFuel_deterministic`. These same-fuel theorems
are currently direct function determinism facts. They are still useful theorem
targets because a later relational evaluator should preserve the same shape
with a more meaningful proof.

The low-risk evaluator equality and parameter helpers are now total:

- `beqValue`, `beqValues`, `beqAttrs`
- `equalValue`, `equalValues`, `equalAttrs`
- `paramEntryNames`, `containsName`, `findExtraAttr?`

They are pure structural recursion over values or lists and no longer live
inside the large partial evaluator mutual block.
