# Fuel is now testable

Evaluation fuel is no longer only a hard-coded constant hidden inside
`CoreEval`.

The default remains `200`, but the CLI accepts:

```sh
lake exe nixparserlean --eval --fuel 0 --file path.nix
```

That gives the e2e runner a direct way to exercise the fuel boundary. The new
fuel manifest checks that forcing a let thunk with zero fuel fails as:

```text
eval error: evaluation fuel exhausted
```

This slice also removes unnecessary `partial` markers from the simple
desugaring inherit walkers. The remaining `partial` clusters are now inventoried
in `docs/partial-and-fuel.md`, separated into parser, validation, desugaring,
and evaluation debt.
