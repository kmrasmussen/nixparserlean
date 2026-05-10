# Plan: parameter defaults

The next high-value parser gap is function parameter defaults:

```nix
{ pkgs, lib ? pkgs.lib, stdenv ? pkgs.stdenv, ... }: body
```

This sits directly on the lambda work that just landed. The parser can already
recognize attribute-set parameters, open parameter sets, and aliases. Defaults
are the next piece that makes this surface look like real nixpkgs code.

The implementation plan is intentionally narrow:

1. Replace `ParamSet.names : List String` with a list of parameter entries.
2. Represent each entry as a name plus an optional default expression.
3. Teach `parseParamSet` to parse `name ? expr`.
4. Validate default expressions the same way string interpolations and selected
   defaults are validated.
5. Add smoke fixtures for defaults alone and defaults inside aliased parameters.

This still leaves richer destructuring metadata for later, but it moves the
surface AST in the right direction: parameter sets are structured syntax, not
just a list of names.
