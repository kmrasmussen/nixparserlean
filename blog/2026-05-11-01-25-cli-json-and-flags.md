# CLI flags stop being source text

The CLI now has an actual option parser.

Unknown flags fail fast:

```text
unknown flag: --typo
```

and `--help` lists the supported surface, core, eval, fuel, and formatting
options. This removes the old surprise where a typo like `--typo` was treated
as inline Nix source.

There is also a stable JSON output mode:

```sh
lake exe nixparserlean --format json --file example.nix
lake exe nixparserlean --desugar --format json --file example.nix
lake exe nixparserlean --eval --format json --file example.nix
```

The default `repr` output remains for humans and existing habits, but tools now
have a constructor-shaped JSON schema to consume.
