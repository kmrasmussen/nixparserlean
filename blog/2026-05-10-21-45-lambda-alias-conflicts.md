# Lambda alias conflicts

Aliased attrset parameters now reject a name collision that Nix treats as
invalid:

```nix
args@{ args, ... }: args
```

and the reverse spelling:

```nix
{ args, ... }@args: args
```

Both parser forms already normalize to one syntax tree shape, so the validator
can enforce the rule once. The same invariant is mirrored in core validation,
which keeps direct core construction from describing a lambda parameter where
the alias would be immediately shadowed by a destructured entry.

The smoke suite now has fixtures for both spellings. Existing aliased parameter
fixtures still pass, so the accepted behavior remains narrow: aliases are fine,
but an alias cannot reuse a destructured field name.
