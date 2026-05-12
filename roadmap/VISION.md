# Vision

NixParserLean is a Lean-backed semantic lens for Nix.

Its goal is to make real Nix code parseable, explainable, analyzable, and
eventually checkable by proofs over a small explicit core. The project should
help a user answer:

- What structure is present in this Nix file?
- Which bindings, attrpaths, imports, and semantic boundaries does it contain?
- What does the surface syntax lower into?
- Which parts can be evaluated purely?
- Which parts require host effects?
- Which invariants are checked by Lean rather than trusted by convention?

The project is grounded in real Nix syntax and corpus coverage, but it should
not define success as quickly cloning every operational detail of C++ Nix.
Success is a growing chain of precise artifacts:

```text
real Nix input
  -> source-positioned surface syntax
  -> semantic validation
  -> explicit core
  -> pure or host-aware evaluation lanes
  -> analysis artifacts
  -> checked theorems
```

## Product Shape

The near-term product is a command-line tool and Lean library that can inspect
real Nix files and emit reliable explanations.

Examples of useful outputs:

- structured parse and validation errors with source positions;
- binding and attrpath summaries;
- import graph and import-boundary summaries;
- desugared core for selected files or expressions;
- evaluator diagnostics that distinguish unsupported pure constructs from
  host-effect boundaries;
- JSON output stable enough for downstream tools.

This gives the project practical value before full Nix evaluation exists.

## Proof Shape

The proof target is not "all of Nix" in one step. The proof target is the
stable model the project builds:

- total validation predicates for surface and core syntax;
- total desugaring over explicit fuel or structural recursion;
- restricted desugar-to-core-validation preservation;
- evaluator fuel monotonicity for growing pure subsets;
- determinism and semantic invariants for named fragments;
- eventually, a small-step or relational semantics connected to the executable
  evaluator.

Theorems should name their restrictions clearly. A small checked theorem over a
real executable subset is more valuable than a broad theorem statement detached
from implementation.

## Strategic Principles

1. **Read Real Nix**
   Corpus coverage keeps the project honest. Parser features should be chosen
   from pinned real files, representative fixtures, and source-positioned
   diagnostics.

2. **Explain Before Completing**
   The project should expose useful structure before it can evaluate all of
   Nix. Import graphs, binding trees, desugaring explanations, and clear
   unsupported-case diagnostics are first-class outcomes.

3. **Keep The Core Small**
   Surface syntax should lower into a core that is explicit enough to inspect
   and small enough to reason about. Forms that remain in core need a named
   reason and eventually a named invariant.

4. **Name Host Effects**
   Pure evaluation must stay filesystem-free. Imports, search paths, path
   normalization, and any future store behavior belong in an explicit
   host-effect lane.

5. **Let Proofs Follow Stable Boundaries**
   Proof work should follow executable layers that are already tested:
   validators, desugaring, core validation, pure evaluation, and host-boundary
   classification.

6. **Keep Ambition Reviewable**
   Each significant step should be narrow enough to review, covered by a
   fixture or theorem, explained in a blog note, and committed without
   unrelated worktree changes.

## Non-Goals For Now

- A drop-in replacement for Nix.
- Modeling derivation realization, string contexts, store copying, or network
  fetchers.
- Letting host filesystem behavior leak into the pure evaluator.
- Treating parsing as the whole project.
- Treating proofs as detached from real Nix-shaped input.

## North-Star Demo

A compelling future demo should look like this:

```sh
nixparserlean explain ./default.nix --json
```

It should parse a real file, report source-positioned structure, show imports
and binding shapes, classify host-effect boundaries, optionally show desugared
core, and identify which checked invariants apply. Some parts may still be
unsupported, but the unsupported parts should be named precisely.

That demo is the bridge between the practical project and the proof project:
real input becomes explicit artifacts, and selected artifacts become theorem
targets.
