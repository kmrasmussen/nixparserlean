# Flagged

Things in the codebase that look load-bearing but are still shortcuts or
deliberate first cuts. Ordered roughly by how much they could surprise a reader
who trusts the manifests.

References use `path:line` against the current tree at the time this note was
written.

---

## 1. Host imports are eager and value-only

`HostEval.lean:173-176` recognises `import` only when the argument is a path
literal. `HostEval.lean:295-318` then reads, parses, validates, desugars,
recursively resolves imports, and evaluates the imported file before the final
pure evaluation pass.

That is a useful first IO boundary, but it is not full Nix import semantics:

- imports are resolved before final evaluation, so they are not lazy.
- imported files are evaluated in isolation and then reified back into core
  syntax.
- imported functions are rejected by `valueToExpr`
  (`HostEval.lean:63-73`) because closures cannot currently be reified.
- only relative `./...` and `../...` paths pass `resolveImportPath`
  (`HostEval.lean:37-44`).

The behavior is documented and covered by `e2e/import-manifest.txt`, but any
claim that "imports work" needs this qualifier.

---

## 2. Path values are inert, not Nix store paths

`CoreEval` now evaluates bare core paths to `Core.Eval.Value.path`, and the
host import layer can reify imported path values back into core syntax.

This is deliberately weaker than full Nix path semantics. Evaluation preserves
the parsed path text and performs no filesystem access, existence check,
normalization, copying to the store, or angle-path lookup. `--eval-imports`
still interprets relative paths only in import position; absolute, home, and
angle imports remain expected `eval-fail` cases.

---

## 3. Empty attribute paths are still a cross-layer invariant

`Desugar.bindingFromPath` now rejects a statically empty lowered path with:

```text
desugar error: empty attribute path
```

The parser should never produce an empty surface attribute path, and
`CoreValidate` would reject empty core paths in selection, existence tests, and
dynamic bindings. The remaining proof gap is connecting parser-produced surface
paths to non-emptiness so the desugar error becomes unreachable by theorem
rather than convention.

---

## 4. `partial` still hides the termination story

TICKET-0007 owns the remaining debt. The simple desugaring helpers have moved
to total definitions, but the parser, validators, surface-to-core walk, and
evaluator still have broad `partial` clusters.

Low-risk examples remain in `CoreEval.lean:266-277`
(`paramEntryNames`, `containsName`, `findExtraAttr?`) and in the equality
helpers near `CoreEval.lean:27-45`. The larger clusters are real proof work:

- parser mutual recursion over shrinking `ParserState`
- validator recursion over mutually-recursive ASTs
- desugaring recursion over mutually-recursive surface/core forms
- evaluation fuel and cycle detection

The roadmap in `docs/roadmap/partial-and-fuel/README.md` describes the order
to attack this without blocking language coverage.

---

## 5. Fuel is a first step budget, not a proven semantics

`CoreEval.lean` now spends fuel on each entry into `Core.Eval.eval`.
Structural walkers do not spend fuel by themselves; they spend when they
evaluate contained expressions. This is deterministic and testable, but it is
still an interpreter budget rather than a separately proved small-step
semantics.

For proof-oriented semantics, the next step is a monotonicity theorem for a
small expression subset, then determinism modulo fuel, then a connection to a
separate step relation.

---

## 6. The repo-local AGENTS checklist under-runs current e2e coverage

`AGENTS.md:23-25` tells contributors to run `lake build` and the default
`e2e/manifest.txt` after parser, validator, CLI, or corpus changes. The flake
check now runs more: parser/validator, core validation, desugar, eval, host
import, fuel, JSON output, and CLI-help checks.

This is a process gap, not a code bug. Contributors following only AGENTS.md
can miss regressions that `nix flake check` would catch.

---

## How to use this list

These are not all bugs. Some are deliberate boundaries that keep the current
implementation reviewable. The point is to keep coverage claims precise:
syntax support, validation support, pure evaluation, and host-backed evaluation
are different layers.
