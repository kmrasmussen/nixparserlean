# Core, Desugaring, Validation, and Evaluation

`NixParserLean/Core.lean` defines the first proof-oriented target language.
`NixParserLean/Desugar.lean` lowers parsed surface syntax into that core.
`NixParserLean/CoreValidate.lean` checks invariants that should hold after
lowering. `NixParserLean/CoreEval.lean` evaluates the supported core
fragment.

The core is intentionally close to the surface language for now, but it has
several differences from the surface AST. The two important ones today are:

- attribute bindings are explicit (`staticAssign` vs. `dynamicAssign`); dotted
  surface paths are merged into nested static attrsets.
- selection and `?` paths are `List AttrPathPart` directly, with no `AttrPath`
  wrapper structure.

## Core bindings

```lean
inductive Core.Binding where
  | staticAssign  : String -> Core.Expr -> Core.Binding
  | inheritAssign : String -> Core.Binding
  | dynamicAssign : List Core.AttrPathPart -> Core.Expr -> Core.Binding
```

Surface dotted paths are lowered before evaluation or proof work sees them:

```nix
{ a.b = 1; a.c = 2; }
```

becomes one static assignment for `a`, whose value is an attribute set
containing `b` and `c`. The merging is implemented by `Desugar.mergeBindings`
and only fires for non-recursive static attrsets.

Dynamic paths stay explicit:

```nix
{ ${key} = 1; "prefix-${key}" = 2; }
```

becomes dynamic assignments whose path parts retain the interpolated
expressions.

## Inherits

The first desugaring pass also lowers inherit forms:

```nix
inherit x;
inherit (scope) y;
```

become explicit core inherit/select bindings:

```nix
inheritAssign "x"
y = scope.y;
```

`inheritAssign` lets the evaluator copy from the enclosing environment even in
recursive scopes, while `inherit (scope) y;` lowers to a static assignment that
selects from the scope expression.

## CLI

Normal output prints the parsed surface AST:

```sh
lake exe nixparserlean --file path/to/file.nix
```

Core output is opt-in:

```sh
lake exe nixparserlean --desugar --file path/to/file.nix
```

The evaluator is also opt-in:

```sh
lake exe nixparserlean --eval --file path/to/file.nix
```

Relative imports are handled by an explicit host IO path:

```sh
lake exe nixparserlean --eval-imports --file path/to/file.nix
```

Parsing and surface validation always run first. Desugaring only happens
after the surface tree is structurally and semantically accepted. The core
tree is then passed to core validation, and only printed (or evaluated) if
that succeeds.

## Evaluation

`NixParserLean/CoreEval.lean` defines a small evaluator. It currently
supports:

- integers, floats as values, booleans, null, strings (text + interpolation),
  lists, attrsets
- recursive `let` bindings via lazy thunks with cycle detection
- recursive `rec { ... }` static attribute sets via the same thunking machinery
- static and dynamic attribute selection and selection defaults (`a.b or x`)
- attribute existence tests (`a ? b`)
- conditionals and assertions
- identifier-parameter lambdas and function application
- attribute-set lambda parameters with defaults and `...` ellipsis
- aliased attribute-set lambda parameters (`args@{ ... }` and `{ ... }@args`)
- `with attrs; body` lookup fallback through the attrset's names
- dynamic attribute names in non-recursive attrsets and in selection paths
- string interpolation of strings, integers, booleans, and null
- boolean negation, integer negation
- integer and float `+`, `-`, `*`, `/` (with division-by-zero check)
- list concatenation with `++`
- shallow attrset update with `//`, where right-hand attributes override
  same-named left-hand attributes
- numeric comparisons (`<`, `>`, `<=`, `>=`) over integers, floats, and
  mixed integer/float operands
- equality, inequality, `&&`, `||`, and implication over supported values

Float arithmetic uses Lean's `Float` for computation and stores the resulting
value with `Float.toString` formatting. Integer-only arithmetic keeps returning
integer values; mixed integer/float arithmetic returns a float value.

Default parameter expressions are evaluated when the corresponding argument
field is absent. A default can refer to earlier-bound parameters, but not
later ones (the env is built in declaration order).

Static `let` bindings are recursive: a binding can refer to a later binding
in the same `let`. Self-recursive cycles fail with an `eval error:` instead
of looping. Mutual recursion that bottoms out (e.g. `a = b; b = 1`) succeeds;
mutual recursion without a base case (e.g. `a = b; b = a`) is detected as a
cycle.

The evaluator decrements a fuel counter (`defaultFuel = 200`) on each entry
into `Core.Eval.eval`. Structural list, binding, and parameter walkers spend
fuel only when they evaluate contained expressions. Exhausting fuel produces an
`eval error: evaluation fuel exhausted`.

Unsupported forms fail explicitly with an `eval error:` prefix. The evaluator
does **not** currently implement:

- pure `--eval` import evaluation, derivations, store paths, network access
- aliased *non-attrset* lambda parameters (`x@y` shapes the AST does not
  produce today, but the evaluator still rejects them defensively)
- dynamic attribute keys inside *recursive* attrsets or `let`
- string interpolation of floats, paths, lists, attrsets, and closures

`NixParserLean/HostEval.lean` provides `--eval-imports`, an IO-aware wrapper
for relative `./...` and `../...` imports. It reads the imported file, runs the
same parse/validate/desugar/core-validation pipeline, evaluates that file in
isolation, and reifies representable values back into core syntax before the
final pure evaluation pass. Imported functions, angle paths, home paths,
absolute path policy, store paths, and network fetchers remain unsupported.

## Core validation

The core validation pass (`Core.validate`) checks:

- static binding names are unique at each binding level
- dynamic assignments have a non-empty path
- selections and attribute-existence tests have non-empty paths
- expressions inside dynamic path segments and string interpolations are valid
- attribute-set lambda parameter names are unique

Surface validation still owns surface-language errors such as duplicate
dotted bindings and prefix conflicts. Core validation is a backstop for the
desugaring target: it records the invariants later evaluation and proofs
should be able to assume.

Core validation errors are formatted as `core error: ...`; the Rust e2e runner
classifies that prefix as `core-fail`, and
`e2e/core-validation-manifest.txt` exercises the contract.

## Values

The evaluator's value type is:

```lean
inductive Value where
  | int : Int -> Value
  | float : String -> Value
  | str : String -> Value
  | bool : Bool -> Value
  | null : Value
  | path : String -> Value
  | list : List Value -> Value
  | attrset : List (String × Value) -> Value
  | closure : List (String × EnvValue) -> LambdaParam -> Expr -> Value
```

`EnvValue` is either a forced `Value` or an unforced `thunk` that captures the
context (`"let"` or `"attribute"`), the base environment, the sibling bindings
needed to reconstruct a recursive scope, and the body expression. Equality
on values is structural for primitives, paths, lists, and attrsets, and is
always `false` for closures.
