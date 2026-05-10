# The core language starts to run

The project now has a first evaluator.

It is deliberately small. The evaluator lives in `CoreEval.lean` and runs only
the checked core fragment that is clear enough to give semantics today:

- literals and lists
- text-only strings
- non-recursive attrsets
- `let` bindings through an environment
- static attribute selection and defaults
- conditionals and assertions
- integer arithmetic
- basic boolean operators

Unsupported forms fail with `eval error:` instead of being guessed. Lambdas,
function application, recursion, dynamic attributes, paths, imports, `with`,
and string interpolation are all still outside the first fragment.

The CLI now has `--eval`, which runs the whole pipeline:

```text
parse -> surface validate -> desugar -> core validate -> eval
```

The e2e runner learned an `eval-fail` expectation, and `e2e/eval-manifest.txt`
keeps the evaluator honest without pretending it covers all of Nix.

This is the first executable semantics for the project. It is small, but it is
the right kind of small: explicit, checked, and ready to grow by adding semantic
cases one at a time.
