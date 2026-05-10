# Lambda parameter aliases

Function parameters can now keep both the full argument set and the destructured
view of that set:

```nix
args@{ pkgs, ... }: pkgs.hello
```

The AST models this as an alias wrapped around another lambda parameter. That
keeps the representation composable: the inner parameter can remain the existing
attribute-set parameter, while the alias names the original value.

The parser also accepts the reverse spelling:

```nix
{ pkgs }@args: args ? pkgs
```

Both forms land in the same AST shape. That is useful because downstream passes
should not have to remember which surface spelling was used unless source
preservation becomes a goal later.

This closes another common module-system gap. Nix code often destructures a few
fields but still keeps the whole argument set around for forwarding, existence
checks, or passing through to helper functions.
