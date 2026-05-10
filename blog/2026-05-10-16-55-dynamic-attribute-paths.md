# Dynamic attribute paths cross the model boundary

Attribute paths are no longer just `List String`.

That was the right starting point for static paths like `a.b.c`, and it even
worked for quoted static names like `"foo-bar"`. But real Nix also has dynamic
attribute names:

```nix
{
  ${key} = 1;
  "prefix-${key}" = 2;
}
```

The AST now represents each path segment explicitly. A segment is either a
static name or a dynamic string made from `StringPart`s. That means the embedded
expressions are preserved in the tree instead of being flattened into a fake
string.

Validation had to become more honest at the same time. Duplicate and prefix
conflict checks still run for fully static paths. If a path contains a dynamic
segment, the validator validates the embedded expressions but does not pretend
it can compare the final runtime key. That is the important semantic line:
static facts stay static, dynamic facts remain available for desugaring and
evaluation.

This is the first step where parser coverage forced a better semantic model.
The next interesting layer is to desugar surface attribute paths into a smaller
core form where static and dynamic binding behavior is explicit.
