# Static Select Default Lowering

The first core simplification is intentionally narrow: static selection
defaults no longer need to survive as a core select-default branch.

For static non-empty paths, desugaring now turns:

```nix
attrs.missing or fallback
```

into a core conditional over `hasAttr`, selecting the value only when the path
exists and otherwise evaluating the fallback. Dynamic-path defaults still keep
the existing core select-default representation so dynamic path expressions are
not duplicated.

The new desugar and eval fixtures cover the simplified lowering path, and the
existing eval suite still passes. The preservation theorem is still a TODO, but
the claim is now named next to the lowering in `Desugar.lean`.

