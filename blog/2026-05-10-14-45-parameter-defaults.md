# Parameter defaults

Attribute-set lambda parameters now carry structured entries instead of just
names.

That makes this surface form parse:

```nix
{ pkgs, lib ? pkgs.lib, ... }: lib
```

Each parameter entry has a name and an optional default expression. Bare
parameters become entries with `default? = none`; parameters with `?` carry the
parsed expression tree.

This required pulling `LambdaParam`, `ParamSet`, and the new `ParamEntry` into
the same recursive AST family as `Expr`. That is the right tradeoff: defaults
are expressions, and aliases can wrap parameter sets, so the type structure
should admit that recursion directly rather than hide it outside the model.

Validation now walks defaults too. A default expression can contain selections,
interpolated strings, assertions, or any other supported expression form, and it
will be checked before the lambda is accepted.

The new smoke fixtures cover both plain and aliased parameter sets:

```nix
{ pkgs, lib ? pkgs.lib, ... }: lib
args@{ pkgs, lib ? pkgs.lib, ... }: args ? lib
```

This moves the lambda surface much closer to real nixpkgs function headers.
