# Flake-owned Rust formatting

Rust formatting is now provided by the flake.

The Rust runner already built and ran through `nix develop`, but `cargo fmt`
escaped to a host `rustup` shim because `rustfmt` was not part of the dev shell.
That made formatting depend on the user's global Rust setup instead of the
repository environment.

The flake now includes `pkgs.rustfmt` alongside `pkgs.cargo` and `pkgs.rustc` in
both the development shell and the e2e check inputs. Running:

```sh
nix develop -c cargo fmt --manifest-path e2e/runner/Cargo.toml
```

now resolves `rustfmt` from `/nix/store`, not from the host system.

This keeps the Rust side of the harness under the same reproducible toolchain
discipline as the Lean parser.
