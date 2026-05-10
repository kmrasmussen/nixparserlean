# Failures by layer

The e2e corpus now distinguishes parse failures from validation failures.

That matters because the parser and validator answer different questions.
Malformed syntax should fail before there is an AST:

```nix
{
  broken 1;
}
```

Duplicate bindings, on the other hand, parse just fine but fail validation:

```nix
{
  a = 1;
  a = 2;
}
```

The manifest now uses three outcomes:

- `pass`
- `parse-fail`
- `validation-fail`

That keeps expected failures useful instead of vague. As this grows toward
Nix-evaluator-shaped behavior, the corpus can say which layer caught a problem:
syntax, validation, or later evaluation. The current validator only checks
duplicate bindings, but the testing shape is ready for stricter rules.

The next interesting frontier is to model binding trees rather than flat binding
names. Exact duplicates like `a = 1; a = 2;` are easy. Prefix conflicts like
`a = 1; a.b = 2;` require understanding how Nix attribute paths expand into a
tree, and that is exactly the kind of check Lean should eventually make precise.
