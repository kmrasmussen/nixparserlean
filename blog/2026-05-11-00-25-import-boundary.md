# Import stays outside the pure evaluator

`import ./file.nix` now has an explicit evaluator boundary.

Previously the expression failed because `import` was just an unbound
identifier. That was technically a failure, but it did not explain the semantic
choice. The evaluator now recognises application of `import` and rejects it as:

```text
eval error: unsupported import evaluation
```

Path literals still parse and desugar, and bare path values still fail as
unsupported evaluator values. The important part is that filesystem IO has not
silently entered `CoreEval`: importing needs a deliberate host IO layer, base
directory policy, and path-normalisation story.

`docs/import-and-path-boundary.md` records the current boundary, and the eval
manifest now includes a local-file import fixture that is expected to fail for
that reason.
