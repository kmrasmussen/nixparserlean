# Control flow, scope, and selection

After lambdas, the parser grew two more everyday Nix expression forms:

```nix
if true then "yes" else "no"
```

and:

```nix
with { value = 1; };
value
```

It also has a first attribute-selection node:

```nix
pkgs.hello
```

These are intentionally small slices, but they matter because they put more real
expression structure into the AST instead of treating keywords and dotted names
as ordinary identifiers. Conditionals now have separate condition, then, and
else branches. `with` has a scope expression and a body expression. Selection
has a base expression and an attribute path.

This keeps the parser on the same path as the lambda work: add one real syntax
shape at a time, represent it explicitly, and immediately pin it with a smoke
fixture. The smoke corpus now checks literals, lists, attribute sets, comments,
`let ... in`, lambdas, conditionals, and `with`.

The next hard edge is precedence. Function application and binary operators are
not independent features in real Nix code; they interact with selection. That is
probably where the current atom-first parser should grow a proper expression
precedence layer instead of adding more keyword cases.
