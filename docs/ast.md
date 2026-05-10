# AST Reference

All types are defined in `NixParserLean/Syntax.lean` inside the `NixParserLean` namespace.

## `Expr`

The main expression type. A Nix program is a single `Expr`.

| Constructor | Fields | Nix example |
|---|---|---|
| `int` | `Int` | `42`, `-1` |
| `str` | `List StringPart` | `"hello ${name}"` |
| `bool` | `Bool` | `true`, `false` |
| `null` | — | `null` |
| `ident` | `String` | `pkgs` |
| `path` | `String` | `./foo.nix`, `<nixpkgs>`, `~/bar` |
| `list` | `List Expr` | `[ 1 "a" true ]` |
| `attrset` | `recursive : Bool`, `bindings : List Binding` | `{ x = 1; }`, `rec { n = n + 1; }` |
| `letIn` | `bindings : List Binding`, `body : Expr` | `let x = 1; in x` |
| `lambda` | `param : LambdaParam`, `body : Expr` | `x: x + 1`, `{ pkgs }: pkgs` |
| `ifThenElse` | `condition`, `thenBranch`, `elseBranch : Expr` | `if b then 1 else 0` |
| `assertExpr` | `condition : Expr`, `body : Expr` | `assert ok; body` |
| `withExpr` | `scope : Expr`, `body : Expr` | `with pkgs; [ curl ]` |
| `select` | `base : Expr`, `path : AttrPath`, `default? : Option Expr` | `a.b.c`, `a.b or fallback` |
| `hasAttr` | `base : Expr`, `path : AttrPath` | `a ? b.c` |
| `app` | `function : Expr`, `argument : Expr` | `f x` |
| `unary` | `op : UnaryOp`, `expr : Expr` | `!ok`, `-value` |
| `binary` | `op : BinaryOp`, `left : Expr`, `right : Expr` | `a + b`, `a == b` |

`Expr` is a `mutual` inductive with `Binding` to allow recursive nesting.

### `Expr.isAtomic`

Returns `true` for `int`, `str`, `bool`, `null`, `ident`, and `path`. Used to determine whether a pretty-printer would need parentheses (not yet implemented).

## `Binding`

Represents one binding inside an attribute set or `let` expression.

| Constructor | Fields | Nix example |
|---|---|---|
| `assign` | `path : AttrPath`, `value : Expr` | `x.y = 1;` |
| `inherit` | `names : List String` | `inherit a b;` |
| `inheritFrom` | `scope : Expr`, `names : List String` | `inherit (pkgs) curl git;` |

### `Binding.path?`

Returns `some path` for `assign`, `none` for the two `inherit` forms.

## `AttrPath` and `AttrPathPart`

A dot-separated attribute path such as `a.b.c`, `a."foo-bar"`, or
`a.${name}`.

```lean
structure AttrPath where
  parts : List AttrPathPart

inductive AttrPathPart where
  | static : String -> AttrPathPart
  | dynamicString : List StringPart -> AttrPathPart
```

Static segments store a known attribute name. Dynamic string segments store the
parsed string parts so interpolated expressions remain visible to validation
and later desugaring. `AttrPath.toString` joins static parts with `"."` and
prints dynamic parts as `"<dynamic>"`.

## `LambdaParam`

The parameter of a lambda expression.

| Constructor | Fields | Nix example |
|---|---|---|
| `ident` | `String` | `x: ...` |
| `attrset` | `ParamSet` | `{ a, b, ... }: ...` |
| `alias` | `String`, `LambdaParam` | `args@{ a }: ...`, `{ a }@args: ...` |

## `ParamEntry`

One entry inside a destructured attribute-set parameter.

```lean
structure ParamEntry where
  name     : String
  default? : Option Expr := none
```

`default? = some expr` corresponds to `{ name ? expr }: ...`.

## `ParamSet`

A destructured attribute-set parameter.

```lean
structure ParamSet where
  entries  : List ParamEntry
  ellipsis : Bool := false
```

`ellipsis = true` corresponds to the `...` token, meaning the function accepts extra attributes beyond the named ones.

## `BinaryOp`

| Constructor | Nix operator |
|---|---|
| `equal` | `==` |
| `notEqual` | `!=` |
| `less` | `<` |
| `greater` | `>` |
| `lessOrEqual` | `<=` |
| `greaterOrEqual` | `>=` |
| `and` | `&&` |
| `or` | `\|\|` |
| `implies` | `->` |
| `add` | `+` |
| `subtract` | `-` |
| `multiply` | `*` |
| `divide` | `/` |
| `concat` | `++` |
| `update` | `//` |

## `UnaryOp`

| Constructor | Nix operator |
|---|---|
| `not` | `!` |
| `negate` | unary `-` |

## `StringPart`

| Constructor | Fields | Nix example |
|---|---|---|
| `text` | `String` | literal string text |
| `interpolation` | `Expr` | `"${expr}"` or `''${expr}''` |
