# Assert expressions

The parser now recognizes Nix assertions:

```nix
assert 1 < 2; "ok"
```

Assertions are represented directly in the AST as a condition and a body. That
keeps them distinct from conditionals: an `if` chooses between two branches,
while an `assert` requires one expression to hold before continuing to the next.

Validation follows both sides. The condition can contain the same expression
forms as any other Nix code, and the body continues through the existing
validation pass.

This is a small syntax addition, but it is part of making the parser useful on
real package and module code. Nixpkgs uses assertions to state platform,
dependency, and configuration constraints close to the expressions they guard.
