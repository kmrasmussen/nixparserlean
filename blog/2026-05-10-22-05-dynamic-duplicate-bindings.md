# Dynamic duplicate bindings fail

Dynamic attribute names are useful only if they obey the same binding rules as
static names. Until now, evaluation silently overwrote earlier attributes when
a dynamic path produced an existing key:

```nix
{ a = 1; ${"a"} = 2; }.a
```

That is now an explicit eval failure:

```text
eval error: duplicate attribute 'a'
```

The evaluator now distinguishes adding a fresh attribute from replacing a
parent attrset after inserting a nested child. That lets `{ ${key}.b = 1; }`
still build nested attributes, while collisions such as static plus dynamic,
dynamic plus dynamic, and dynamic overwrites of an existing prefix are rejected.

This keeps the core evaluator from drifting into last-binding-wins behavior,
which would make real Nix code look deceptively valid in Lean.
