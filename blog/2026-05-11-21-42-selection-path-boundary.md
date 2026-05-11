# Selection and Path Boundary

The external corpus had two different failures around the same parser boundary:
dynamic selections formatted on a following line, and dot-file paths used as
function arguments.

The parser now keeps ordinary selection and attrpath dots whitespace-tight, but
allows the specific real-world dynamic selector shape:

```nix
attrs
  .${name}
```

That keeps `lib.strings.fileContents ./.version` available to application
parsing as a path argument, while still accepting the nixpkgs cases that split
the dynamic selector from the attrset expression.

The new smoke coverage has three layers:

- `spaced-dynamic-selection.nix` proves the parser accepts the newline dynamic
  selector form.
- `eval-spaced-dynamic-selection.nix` proves the resulting dynamic selection
  still evaluates through the core evaluator.
- `dot-file-path-argument.nix` proves `fileContents ./.version` parses as
  application to a path literal.

The pinned external corpus now advances `lib/types.nix`,
`lib/systems/default.nix`, and `lib/trivial.nix` to `pass`. The remaining
expected parse blockers are narrower: quoted inherit names in `lib/default.nix`
and the indented string escape policy in `lib/strings.nix`.

