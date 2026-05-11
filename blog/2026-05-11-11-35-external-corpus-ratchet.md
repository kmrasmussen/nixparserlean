# External Corpus Ratchet

The external manifest is now large enough to be useful as a real parser
ratchet instead of a tiny smoke afterthought.

It covers 15 pinned nixpkgs files from the same revision as `flake.lock`.
Ten parse successfully. Five are expected parse failures, and each failure now
starts with a stable blocker category:

```text
2 spaced-dynamic-selection
1 quoted-inherit-name
1 path-argument-dot-file
1 indented-string-escape
```

This matters because the external corpus should answer a different question
from the committed smoke fixtures. Smoke fixtures prove intentional behavior
stays stable. The external corpus tells us which real Nix constructs are still
stopping larger files.

The highest-frequency blocker is already clear: selections such as:

```nix
{
  ...
}
.${name} or fallback
```

Two files stop there. That makes it a better next parser target than a
one-off construct, unless a smaller prerequisite falls out first.

The docs now include the external runner command and a small `awk` report that
summarizes blocker categories directly from `e2e/external-manifest.txt`.
