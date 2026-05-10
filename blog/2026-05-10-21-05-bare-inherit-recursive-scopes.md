# Bare inherit in recursive scopes

Bare `inherit` now has an explicit core binding form.

That sounds small, but it marks an important semantic boundary. Lowering
`inherit x;` to `x = x` made the evaluator lose the difference between copying
an outer name and defining a recursive self-reference. In a `let` or `rec`
attribute set, that distinction matters: the ordinary assignment shadows the
outer `x` before the right-hand side is forced.

The new core binding preserves the intent without changing the surface syntax.
Recursive environments install inherited entries that read from the base
environment, while ordinary assignments keep their recursive thunk behavior.
Scoped inherit, such as `inherit (pkgs) hello;`, still lowers through selection
and is unchanged.

The new eval fixtures cover all three relevant shapes:

```nix
let x = 1; in let inherit x; in x
```

```nix
let x = 1; in rec { inherit x; y = x + 1; }.y
```

```nix
let x = 1; in { inherit x; }.x
```

This is the kind of progress that makes the core model more honest. We are not
just making a failing example pass; we are teaching the intermediate language a
semantic distinction that Nix programmers rely on.
