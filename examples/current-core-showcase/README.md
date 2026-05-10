# Current Core Showcase

This example is a compact demonstration of the strongest behavior currently
handled end to end by the Lean parser, desugarer, validator, and evaluator.

Run it with:

```sh
nix develop -c lake exe nixparserlean --eval --file examples/current-core-showcase/showcase.nix
```

The result is:

```text
NixParserLean.Core.Eval.Value.int 84
```

The example combines:

- recursive attribute sets: `defaults.total` and `package.doubled`
- aliased attrset lambda parameters: `args@{ ... }`
- parameter defaults that inspect the full argument through the alias
- dynamic quoted attribute names: `"${package.label}-${key}"`
- attribute selection through evaluated dynamic names
- `with` fallback lookup for the final `demo-score` name

The same `showcase.nix` file is part of the eval e2e manifest, so this example
is both documentation and a regression test.
