# External corpus manifests begin

The Rust e2e runner now has a manifest entry layer.

The old smoke manifest still works:

```text
path/to/file.nix<TAB>pass<TAB>note
```

But the runner also accepts explicit local entries:

```text
file<TAB>path/to/file.nix<TAB>pass<TAB>note
```

and external URL entries:

```text
url<TAB>cache-name.nix<TAB>https://example.test/file.nix<TAB>parse-fail<TAB>note
```

URL entries are downloaded with `curl` into a cache directory, defaulting to
`e2e/cache`, and then run through the same parser path as committed fixtures.
This is deliberately small: no dependency stack, no registry format, and no
hash enforcement yet. The goal is to create the harness seam where those pieces
can attach.

An example manifest now lives at `e2e/external-manifest.example.txt`. It is not
part of the default smoke run. That keeps ordinary development fast and
reproducible while giving the project a concrete starting point for real-world
corpus expansion.

This is the first infrastructure step toward letting real nixpkgs files drive
the parser roadmap continuously instead of manually.
