# External Corpus Infrastructure

With the first pinned external corpus green, the useful work shifts from
one-off blockers to maintenance.

The new `e2e/external-summary.sh` script summarizes the manifest without
running the parser:

```sh
e2e/external-summary.sh e2e/external-manifest.txt
```

For the current manifest it reports 15 cases, 15 passes, and no external
blockers. When expected failures return in a larger corpus, the script groups
them by the stable `blocker: ...` prefix.

The external manifest now also documents a compatible provenance policy:
URL rows should use immutable upstream revisions, and optional content hashes
can be recorded as ignored `# sha256<TAB>cache-name<TAB>hash` comments before a
URL row. That keeps old runner behavior unchanged while giving future refreshes
a place to record intent.

The external run remains separate from `nix flake check`; network-backed corpus
refreshes should stay explicit.

