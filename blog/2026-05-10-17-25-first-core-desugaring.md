# The first core language appears

The project now has a second language inside it.

The parser still produces the surface AST. That tree is useful because it
records what the user wrote. But it is not the shape we want for semantics and
proofs forever. Surface Nix has too many conveniences mixed directly into
expressions and bindings.

This slice adds `Core.lean` and `Desugar.lean`. The core is still deliberately
small and conservative, but attribute bindings are now explicit:

```lean
Core.Binding.staticAssign  : String -> Core.Expr -> Core.Binding
Core.Binding.dynamicAssign : List Core.AttrPathPart -> Core.Expr -> Core.Binding
```

That lets dotted static paths lower into nested core attrsets:

```nix
{ a.b = 1; a.c = 2; }
```

becomes a single static `a` branch containing `b` and `c`. Dynamic attribute
paths remain dynamic assignments, preserving their interpolated expressions for
later evaluation semantics.

The pass also lowers simple inherit forms. `inherit x;` becomes `x = x`, and
`inherit (scope) y;` becomes `y = scope.y` in the core representation.

The CLI now has an opt-in `--desugar` mode. The normal parser output is
unchanged, but we can ask the executable to print the core AST after parsing and
validation. The smoke corpus passes through that mode too, which gives this new
layer a basic integration check.

This is the project turning a corner: parser coverage is no longer the endpoint.
Each surface feature now has somewhere more semantic to go.
