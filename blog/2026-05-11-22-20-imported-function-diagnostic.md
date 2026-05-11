# Imported Function Diagnostic

The host import lane now has explicit fixture coverage for imported functions.

`--eval-imports` still evaluates imported files in isolation and reifies
representable values back into core syntax for the final pure pass. Closures
cannot be reified yet, so importing a file that evaluates to a function fails
with:

```text
eval error: unsupported imported function values
```

The new import-manifest row proves that this remains an `eval-fail`, not an
unclassified failure. The docs now call out the closure reification boundary
next to the existing relative-import and path-value policy.

