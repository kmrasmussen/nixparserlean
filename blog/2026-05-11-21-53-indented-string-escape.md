# Indented String Escape

The final blocker in the pinned external corpus was an indented string that
needed a literal `${...}` sequence:

```nix
''
  "''${path}"
''
```

Indented strings now recognize `''${` as a literal `${` escape. Ordinary
`${expr}` interpolation still works, and the new eval fixture checks both forms
in the same string.

This is intentionally a small escape-policy slice, not a full Nix string model.
The parser docs now say exactly which quoted-string escapes and indented-string
escapes are supported.

With this change, all 15 rows in the pinned external manifest pass. The next
useful corpus work is infrastructure: hashes, summaries, and refresh lanes
rather than another one-off blocker fix.

