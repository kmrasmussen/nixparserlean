# Attribute access grows defaults and existence checks

Two more common Nix access forms now have explicit AST nodes.

Selection can carry a fallback:

```nix
attrs.missing or attrs.a
```

The `select` constructor now stores an optional default expression. Plain
selection uses `none`; `or` selection uses `some defaultExpr`. Validation follows
that expression when it exists, so defaults are still checked through the same
tree walk as the rest of the program.

The parser also recognizes attribute existence tests:

```nix
attrs ? a.b
```

That lands as `hasAttr base path`, with the right-hand side reusing the existing
attribute path parser. It sits as its own precedence level between equality and
comparison, which keeps expressions like `attrs ? a.b == true` shaped as an
existence check compared with `true`.

These forms are small, but they matter for real Nix. Defaults are common around
optional package attributes, and `?` is one of the basic ways modules and package
sets ask whether a field exists before selecting it.
