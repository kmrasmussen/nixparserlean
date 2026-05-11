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
claim that "imports work" needs this qualifier. Future host-effect work is
tracked in `roadmap/05-host-effects.md`.

---

## 2. Path values are inert, not Nix store paths

`CoreEval` now evaluates bare core paths to `Core.Eval.Value.path`, and the
host import layer can reify imported path values back into core syntax.

This is deliberately weaker than full Nix path semantics. Evaluation preserves
the parsed path text and performs no filesystem access, existence check,
normalization, copying to the store, or angle-path lookup. `--eval-imports`
still interprets relative paths only in import position; absolute, home, and
angle imports remain expected `eval-fail` cases.

Future path and import policy work is tracked in `roadmap/05-host-effects.md`
and `roadmap/03-core-semantics.md`.

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
rather than convention. The next proof contract slice is tracked in
`roadmap/04-proofs-and-totality.md` and `TICKET-0042`.

---

## 4. `partial` still hides the termination story

The simple desugaring helpers have moved to total definitions, and the
surface/core validators are now total fuel-bounded definitions. The parser,
surface-to-core walk, host import walk, and evaluator still have broad
`partial` clusters.

The remaining clusters are real proof work:

- parser mutual recursion over shrinking `ParserState`
- desugaring recursion over mutually-recursive surface/core forms
- evaluation fuel and cycle detection

The active plan is in `roadmap/04-proofs-and-totality.md`; concrete follow-up
tickets include `TICKET-0043`, `TICKET-0044`, and `TICKET-0050`.

---

## 5. Fuel is a first step budget, not a proven semantics

`CoreEval.lean` now spends fuel on each entry into `Core.Eval.eval`.
Structural walkers do not spend fuel by themselves; they spend when they
evaluate contained expressions. This is deterministic and testable, but it is
still an interpreter budget rather than a separately proved small-step
semantics.

For proof-oriented semantics, the next step is a monotonicity theorem for a
small expression subset, then determinism modulo fuel, then a connection to a
separate step relation. This is tracked in
`roadmap/04-proofs-and-totality.md` and `TICKET-0045`.

---

## How to use this list

These are not all bugs. Some are deliberate boundaries that keep the current
implementation reviewable. The point is to keep coverage claims precise:
syntax support, validation support, pure evaluation, and host-backed evaluation
are different layers.
