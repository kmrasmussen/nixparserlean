# Core and Desugaring

`NixParserLean/Core.lean` defines the first proof-oriented target language.
`NixParserLean/Desugar.lean` lowers parsed surface syntax into that core.
`NixParserLean/CoreValidate.lean` checks invariants that should hold after
lowering.

The core is intentionally close to the surface language for now, but it has one
important difference: attribute bindings are explicit.

## Core bindings

```lean
inductive Core.Binding where
  | staticAssign  : String -> Core.Expr -> Core.Binding
  | dynamicAssign : List Core.AttrPathPart -> Core.Expr -> Core.Binding
```

Surface dotted paths are lowered before evaluation or proof work sees them:

```nix
{ a.b = 1; a.c = 2; }
```

becomes one static assignment for `a`, whose value is an attribute set
containing `b` and `c`.

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

become:

```nix
x = x;
y = scope.y;
```

inside the core representation.

## CLI

Normal output still prints the parsed surface AST:

```sh
lake exe nixparserlean --file path/to/file.nix
```

Core output is opt-in:

```sh
lake exe nixparserlean --desugar --file path/to/file.nix
```

Parsing and validation still run first. Desugaring only happens after the
surface tree is structurally and semantically accepted. The resulting core tree
is validated before it is printed.

## Core validation

The first core validation pass checks:

- static binding names are unique at each core binding level
- dynamic assignments have a non-empty path
- selections and attribute existence tests have non-empty paths
- expressions inside dynamic path segments and string interpolations are valid

Surface validation still owns source-language errors such as duplicate dotted
bindings. Core validation is a backstop for the desugaring target: it records
the invariants later evaluation and proofs should be able to assume.
