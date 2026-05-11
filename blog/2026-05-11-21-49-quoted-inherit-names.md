# Quoted Inherit Names

The external corpus had one remaining `quoted-inherit-name` blocker in
`lib/default.nix`:

```nix
inherit (self.trivial)
  "or";
```

Inherit lists now accept static quoted names as well as identifiers. The parser
still rejects dynamic quoted inherit names, because this step is only about the
static name forms used by real nixpkgs code.

The smoke coverage now includes:

- bare and scoped quoted inherit names;
- duplicate validation across `inherit or "or";`;
- the pinned external `lib/default.nix` row moved to `pass`.

After this ratchet, the pinned external manifest has one expected parse
failure left: the indented-string escape policy in `lib/strings.nix`.

