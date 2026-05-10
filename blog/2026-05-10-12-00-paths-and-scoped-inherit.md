# Paths and scoped inherit

The parser now recognizes the first useful set of Nix path literals:

```nix
../modules/service.nix
```

```nix
<nixpkgs>
```

That also makes `import` work naturally as function application instead of as a
special parser case:

```nix
import ./default.nix
```

The important parser detail was the boundary between selection and paths.
`pkgs.hello` is selection, but `import ./default.nix` is an application whose
argument starts with a relative path. Selection now requires the dot to be
adjacent to the base expression, so whitespace can separate an application from
a path argument.

Bindings also grew scoped inherit:

```nix
{
  inherit (pkgs) hello;
}
```

That forced the binding AST to distinguish plain inherited names from names
inherited out of a scope expression. It is a small model change, but it matters
for real Nix code because scoped inherit is everywhere in nixpkgs.

The smoke corpus now covers paths, imports, scoped inherit, application,
selection, lambdas, conditionals, `with`, and a first operator precedence stack.
The parser is still far from complete, but it is now recognizably aimed at real
files rather than only toy examples.
