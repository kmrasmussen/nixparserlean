# Lambdas enter the AST

The parser now has a first real model for Nix functions. It understands simple
identifier parameters like:

```nix
x: x
```

and the attrset parameter shape that shows up constantly in Nix code:

```nix
{ pkgs, ... }:
{
  inherit pkgs;
}
```

This is a meaningful step because lambdas are not just another delimiter form.
They force the syntax tree to represent function parameters separately from
ordinary expressions. A `{ pkgs }:` prefix looks like an attribute set until the
colon arrives, so the parser now has to try the function shape before falling
back to ordinary atom parsing.

The implementation is still deliberately modest. It does not yet support
defaults, aliases with `@`, destructuring metadata, or the full grammar around
function application. That restraint is useful: the AST now has a place for
function syntax, and the smoke corpus can mark lambdas as supported without
claiming the whole Nix parameter language is done.

The next useful pressure is control flow and scope forms. `if ... then ... else`
and `with ...; ...` both appear early in real Nix files, and both are good tests
of whether the expression parser can grow without turning into a pile of
special cases.
