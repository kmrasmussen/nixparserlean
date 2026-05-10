# Validation starts

The parser now has a separate validation pass. Parsing still answers "is this
syntax shaped like Nix?", while validation starts answering "would this survive
the next layer of Nix checks?"

The first validation rule is deliberately concrete: duplicate binding names are
reported as semantic errors. These now fail:

```nix
{
  a = 1;
  a = 2;
}
```

```nix
let
  x = 1;
  x = 2;
in
  x
```

and duplicate inherited names fail too:

```nix
{
  inherit a a;
}
```

This is not evaluation yet. There is no environment, no value forcing, and no
module logic. But it is the right first line: the CLI now parses, validates, and
returns a non-zero exit code for errors that are beyond syntax. The e2e harness
can mark those files as expected failures, which means semantic checks can grow
without needing a separate test framework.

The next validation layer should be more precise about nested attribute paths:
exact duplicates are easy, but prefix collisions like `a = 1; a.b = 2;` need a
real tree of bindings rather than a flat list of names.
