# Default parameters start evaluating

Attribute-set lambdas now support defaults:

```nix
({ a ? 1, b }: a + b) { b = 2; }
```

If the argument attrset provides a field, that value wins. If the field is
absent and the parameter has a default, the evaluator evaluates the default and
binds it into the function body environment.

This slice makes parameter binding order explicit. Defaults are evaluated in the
closure environment extended by earlier parameters. That means this works:

```nix
({ a, b ? a + 1 }: b) { a = 4; }
```

and this fails for now:

```nix
({ a ? b + 1, b }: a) { b = 4; }
```

That is a conservative semantic line. It gives us useful default behavior
without pretending we have modeled every corner of Nix's recursive parameter
scope yet.

The eval manifest now covers default use, explicit override, earlier-parameter
references, and the later-reference failure.
