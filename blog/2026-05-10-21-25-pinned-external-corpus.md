# Pinned external corpus entries

The external corpus now has a real manifest, not just an example format.

`e2e/external-manifest.txt` pins a small set of nixpkgs files to the same
revision used by `flake.lock`. The manifest is deliberately outside the default
smoke check because first use needs network access, but the cached runner path
is now exercised against real files:

```text
e2e: 0 passed, 4 expected parse failures, 0 expected validation failures, 0 expected eval failures, 0 unexpected failures, 0 unexpected successes
```

The important part is the notes. Each expected failure names a missing parser
shape: identifier lambdas in let bindings, top-level attrset lambdas around
documentation comments, attrset lambda defaults, and parenthesized lambdas in
larger real-world expressions.

That gives the project a more useful kind of red: not noisy breakage, but a
stable queue of real Nix constructs that can guide future parser work.
