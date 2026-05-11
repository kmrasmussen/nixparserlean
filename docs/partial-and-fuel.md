# Partial Definitions and Fuel

This inventory records why `partial` remains in the codebase and where it is
intentional debt.

## Parser

`Parser.lean` and `Parser/Basic.lean` still use recursive-descent functions
marked `partial`. The grammar is mutually recursive and backtracking-oriented,
so this is acceptable for now, but structured termination or parser fuel would
eventually make the parser model more proof-friendly.

## Validation

`Validate.lean` and `CoreValidate.lean` still contain mutually recursive
validators over expressions, string parts, lambda parameters, and bindings.
Those definitions are structurally recursive over the AST, but Lean does not
currently see the whole mutual termination argument.

The simple list walkers around conflict and duplicate detection are total.
An attempt to make the validator mutual blocks total showed the next precise
obstacle: Lean cannot infer a shared decreasing measure through derived lists
such as `path.exprs` in the surface validator and `paramSet.entries` in the
core validator. The follow-up shape is to introduce direct attr-path and
parameter-set validator functions, or to give the mutual blocks an explicit
measure that accounts for those derived substructures.

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

The merge helpers are total through an explicit internal fuel bound. This makes
small merge invariants proof-visible while avoiding the older opaque `partial`
definitions. The remaining `partial` desugaring cluster is the real recursive
surface-to-core walk; it should be handled separately because it follows the
mutual AST recursion rather than list-shaped merge recursion.

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

The low-risk evaluator equality and parameter helpers are now total:

- `beqValue`, `beqValues`, `beqAttrs`
- `equalValue`, `equalValues`, `equalAttrs`
- `paramEntryNames`, `containsName`, `findExtraAttr?`

They are pure structural recursion over values or lists and no longer live
inside the large partial evaluator mutual block.
