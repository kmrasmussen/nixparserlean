# Equality and interpolation policy

The evaluator now has a documented policy for two places where it was too
quiet.

Equality is same-kind only. Comparing two supported values of the same kind
still returns a boolean, but heterogeneous comparisons now fail:

```nix
1 == "1"
```

```text
eval error: equality operands must have the same type
```

String interpolation now coerces a small primitive subset: strings, integers,
booleans, and null. Dynamic attribute interpolation remains stricter and still
requires an actual string value. Floats, paths, attrsets, lists, and closures
remain outside this coercion boundary.

The fixtures now cover same-kind equality, heterogeneous `==` and `!=`, int /
bool / null interpolation coercion, and rejected aggregate/float interpolation.
