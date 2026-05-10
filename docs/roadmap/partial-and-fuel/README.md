# Roadmap: Partial and Fuel

This roadmap plans the migration from `partial` definitions toward total or
fuel-bounded definitions across the parser, validators, desugarer, and
evaluator. The end state is a model where the kernel can check termination
arguments for everything except evaluation, and where evaluation's fuel is a
*semantic* parameter rather than an implementation escape hatch.

Anchors:

- Inventory: [`docs/partial-and-fuel.md`](../../partial-and-fuel.md)
- Tracking ticket: `.tickets/TICKET-0007`
- Mission framing: `AGENTS.md`, [`docs/scaling-plan.md`](../../scaling-plan.md)

## End state

1. Validators (`Validate.lean`, `CoreValidate.lean`) are total `def`s with
   Lean-checked structural recursion.
2. Desugaring (`Desugar.lean`) is total, including the static-attrset merge
   helpers, with a documented termination measure.
3. The parser is either fuel-bounded with an obvious decreasing argument
   (remaining input) or has a `decreasing_by` proof on input length.
4. Evaluation remains fuelled, but fuel is defined to count *evaluation
   steps* and has theorems attached: monotonicity in fuel, determinism
   modulo fuel, and a preservation lemma against `CoreValidate` invariants.
5. `partial` survives only where genuinely required, with a comment pointing
   back to this roadmap.

## Phasing

Phases are ordered by *risk*, not by file. Each phase should land as one or
more tickets and leave the build green.

### Phase 1: low-risk list walkers (in progress)

Pure structural recursion on `List`. Already partially done; remaining items
are enumerated in TICKET-0007. No mutual recursion, no measure to invent.

- `Validate.lean`: `findConflictWith`, `firstPathConflict?`,
  `findDuplicateString?`, `staticPartNames?`.
- `CoreValidate.lean`: `findDuplicateString?`, `staticBindingNames`,
  `paramEntryNames`.
- `CoreEval.lean`: `paramEntryNames`, `containsName`, `findExtraAttr?`,
  `beqAttrs` / `beqValues` / `beqValue`.

Risk: low. Blocking concern: Lean 4's auto-termination sometimes refuses
recursion through `List` and needs `List.attach` or explicit `match`.

### Phase 2: AST-recursive validators

The `mutual` blocks in `Validate.lean` and `CoreValidate.lean` recurse over
`Expr`, `Binding`, `LambdaParam`, `StringPart`, and `AttrPathPart`. They are
structurally decreasing on the AST, but the kernel does not currently see
the joint termination argument across the mutual block.

Approach options, cheapest first:

- Pull the recursion into a single non-mutual function over a sum type,
  letting `sizeOf` carry the proof.
- Use `decreasing_by` with the auto-generated `sizeOf` from the AST
  inductive.
- Introduce a `Sized` measure if `sizeOf` does not work through the existing
  `mutual` AST blocks (`Syntax.lean`, `Core.lean`).

Risk: medium. Validators have a fixed result type (`Except String Unit`),
so mechanical conversion should work; the friction is purely in convincing
the kernel.

### Phase 3: desugaring as a total walk

`Desugar.lean` has two recursive surfaces:

- `expr`/`binding`/`stringParts`/... — surface→core walk, structurally
  decreasing on `Expr`. Same shape as Phase 2.
- `mergeStaticAttrsets`/`mergeBindingInto`/`mergeBindings` — recursion on a
  *derived* core structure during merging. The decreasing argument is not
  the surface AST.

The merge cluster needs its own measure. Candidates:

- Total binding count across the two operands (strictly decreases per
  merge step).
- Lexicographic `(left.size, right.size)`.

Document the choice in this folder before coding. The merge invariants
(no duplicate static keys, dynamic bindings preserved in order) should be
restated alongside the measure so the proof obligation is visible.

Risk: medium-high on merging, low on the walk.

### Phase 4: parser termination

The parser is mutually recursive, backtracking, and consumes characters
from a `ParserState`. Termination is not structural over an inductive — it
depends on the input shrinking.

Two viable shapes:

- **Explicit fuel = remaining input length.** Simple, mechanical, but adds
  a parameter everywhere. Acceptable as a first step.
- **`decreasing_by` on input length.** Requires every consuming call to
  prove `state'.input.length < state.input.length`. Cleaner but invasive.

A third option — switching to a parser-combinator library with built-in
termination — is explicitly out of scope for this roadmap; AGENTS.md
favors the existing handwritten style.

Risk: high. The parser is the largest mutual cluster and changes here ripple
into every fixture.

### Phase 5: evaluator and semantic fuel

Nix evaluation is not strongly normalizing; total evaluation is not the
goal. Instead:

1. Redefine fuel to count *evaluation steps*, not just thunk forces. The
   current 200 default becomes meaningful as a step budget.
2. Prove fuel monotonicity: if `eval n e = ok v` then `eval (n+k) e = ok v`.
3. Prove determinism modulo fuel: any two runs that both succeed agree on
   the value.
4. Connect fuel to a small-step relation so `eval` becomes a bounded
   interpreter for a separately-defined semantics.

Phase 5 is gated on Phase 3 (desugaring must be total before eval theorems
are worth stating) and benefits from Phase 2 (validator invariants become
preservation lemmas).

Risk: high. This is where the project transitions from "model" to
"verified model".

### Phase 6: proof harvest

Once the previous phases land, the following theorems become attainable
and should be tracked as separate tickets:

- Determinism of desugaring.
- Soundness of `Validate` w.r.t. `CoreValidate` (every surface program
  that passes surface validation desugars to one that passes core
  validation).
- Preservation: `CoreValidate` invariants are preserved across every
  evaluation step.
- Fuel monotonicity and determinism (from Phase 5).

## Cross-cutting concerns

- **Mutual recursion.** Lean 4 wants a single shared termination argument
  per mutual block. Splitting into non-mutual definitions over sum types is
  often the cheapest workaround.
- **AST changes.** Both `Syntax.lean` and `Core.lean` already use `mutual`.
  If their `sizeOf` is unusable, a hand-written measure may be needed and
  must be added once and reused across phases.
- **Tests stay green.** Every phase must keep `lake build` and the e2e
  runner passing. Conversions are mechanical enough that this is realistic.
- **Blog discipline.** Per AGENTS.md, each phase that lands deserves a
  blog note describing the termination argument chosen, not just the
  diff.

## Out of scope

- Proving termination of arbitrary Nix evaluation.
- Replacing the handwritten parser with a combinator library.
- Performance work; fuel and totality changes are correctness-driven.

## Status

Phase 1 is partially done (the simple desugaring helpers in
`docs/partial-and-fuel.md` are already total). All other phases are
unstarted. Per-phase tickets should be opened as the work begins, linking
back to this document.
