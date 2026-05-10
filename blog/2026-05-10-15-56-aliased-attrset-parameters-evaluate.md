# Aliased Attrset Parameters Evaluate

Nix attrset lambdas can bind the whole argument and destructure fields at the
same time:

```nix
args@{ a, ... }: args.a + a
```

The parser and core language already represented both alias syntaxes, but the
evaluator treated every alias as unsupported. This change teaches function
application to bind aliases around attrset parameters by placing the full
argument value in the environment before running the existing attrset parameter
binder.

That preserves the current behavior for required fields, unexpected fields,
ellipsis, and defaults. It also means defaults can inspect the full argument via
the alias, while still using the same left-to-right parameter binding model as
the rest of the evaluator.

The new smoke fixtures cover `args@{ ... }`, `{ ... }@args`, and a default that
uses the alias. Unsupported non-attrset alias shapes remain explicit eval
errors, which keeps the evaluator honest about the smaller surface it currently
models.
