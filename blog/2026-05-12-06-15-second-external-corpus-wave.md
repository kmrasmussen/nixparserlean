# Second External Corpus Wave

The pinned external nixpkgs corpus has a second wave.

The manifest now has 23 immutable nixpkgs rows from the same locked revision.
The new rows cover additional library areas: asserts, CLI helpers, debugging,
filesystem helpers, generators, metadata, sources, and strings-with-deps.

All eight new rows passed under the existing parser and validator. That is
useful information on its own: this wave did not create new blocker tickets,
so the next corpus work should either choose a more syntactically aggressive
nixpkgs area or improve the external refresh/reporting workflow.

The network-backed external corpus remains outside ordinary `nix flake check`.
It is still an explicit command for parser expansion work:

```sh
nix develop -c cargo run --manifest-path e2e/runner/Cargo.toml -- --manifest e2e/external-manifest.txt
./e2e/external-summary.sh
```
