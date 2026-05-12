# Current State

This is a factual snapshot after the host path and corpus work through
`TICKET-0056`.

## Repository State

- Branch: `master`.
- All `.tickets/TICKET-0001` through `.tickets/TICKET-0056` are marked
  `completed`.
- `./scripts/open-tickets.sh` reports the next ready ticket as `TICKET-0057`.
- `nix flake check` remains the ordinary network-free local gate; the external
  corpus stays outside it.

Recent work completed:

- first and second external corpus waves, with 23 pinned nixpkgs rows passing;
- inert path values and explicit import/path boundary docs;
- total fuel-bounded surface validator, core validator, and desugar walk;
- parser helper totality for `takeWhileGo`, angle path scanning, and the
  additive/multiplicative expression loops;
- quoted inherit names, dot-file path arguments, spaced dynamic selection, and
  escaped indented interpolation;
- static selection-default lowering and empty static binding-name validation;
- focused example suite wired into e2e manifests;
- first checked desugar/core-validation bridge theorem;
- checked evaluator-fuel monotonicity slices for primitive literals,
  primitive-literal binary expressions, and primitive-literal unary expressions;
- host-effect evaluator shape, angle search-path design, parser termination
  strategy, and roadmap maintenance loop.

The root `flagged.md` contains the caveats that still matter: eager value-only
host imports, inert path values, cross-layer attribute-path invariants,
remaining parser/host/evaluator `partial` islands, and incomplete fuel
semantics.

## Supported Surface Syntax

The parser supports the main expression forms needed by the current smoke and
external corpus:

- literals: integers, floats, quoted strings, indented strings, booleans, null,
  and paths;
- lists and attribute sets, including recursive `rec { ... }`;
- `let ... in`;
- identifier lambdas and attrset parameter lambdas;
- parameter defaults, ellipsis, and aliases in both `args@{ ... }` and
  `{ ... }@args` positions;
- `if ... then ... else`, `assert`, and `with`;
- selection, selection defaults, spaced dynamic selection, and attribute
  existence tests;
- function application, including path arguments like `./.version`;
- parenthesized application arguments;
- `inherit` and `inherit (scope)`, including quoted static inherit names;
- static, quoted, and dynamic attribute path parts;
- arithmetic, comparison, boolean, implication, list concat, and attrset update
  operators.

The parser remains handwritten. Many expression/parser functions are still
`partial`, but the termination strategy is now documented and the first local
operator-loop fuel slice has landed.

## Validation Layers

Surface validation checks source-level semantic invariants:

- duplicate bindings and prefix conflicts for static paths;
- duplicate `inherit` names, including quoted static names;
- duplicate attrset lambda parameter entries;
- lambda alias name conflicts;
- recursive validation of expressions embedded in string interpolation and
  dynamic attribute paths.

Core validation checks post-desugaring invariants:

- duplicate static binding names at each core binding level;
- non-empty static binding names;
- non-empty dynamic assignment paths;
- non-empty selection and attribute-existence paths;
- valid expressions inside dynamic paths and string interpolation;
- duplicate core lambda parameter entries and alias conflicts.

Both validators are total definitions using explicit validation fuel:
`defaultValidationFuel = 100000`.

## Desugaring

Surface syntax lowers into `NixParserLean.Core.Expr`.

Current important behavior:

- dotted static paths lower into nested static core attrsets;
- sibling static paths are merged through total fuel-bounded merge helpers;
- dynamic attribute paths remain explicit `dynamicAssign` nodes;
- bare inherit lowers to `inheritAssign`;
- scoped inherit lowers to static selections;
- static selection defaults lower to `hasAttr` plus `select` in `ifThenElse`;
- empty lowered static paths are rejected with
  `desugar error: empty attribute path`.

The main surface-to-core walk is total through explicit desugar fuel. The proof
surface includes lemmas about static path top-level names, nested static path
shape, empty-path rejection, static merge behavior, and one
desugar/core-validation bridge for a restricted static attrset slice.

## Evaluation

The pure evaluator supports a sizeable but intentionally bounded core fragment:

- primitive values, lists, attrsets, strings, and interpolation;
- inert path values;
- recursive `let` and recursive static attrsets via thunks;
- cycle detection for recursive bindings;
- identifier lambdas and attrset lambdas with defaults, ellipsis, and aliases;
- `with` lookup fallback;
- dynamic attribute construction and selection in non-recursive scopes;
- arithmetic, comparisons, equality, booleans, list concat, and attrset update.

Fuel is an entry-step budget: every entry into `Core.Eval.eval` spends one fuel
step. Structural walkers spend fuel only when they evaluate contained
expressions. The checked monotonicity proof harness now covers primitive
literals, primitive-literal binary expressions, and primitive-literal unary
expressions. The next useful widening target is a recursive walker without
environment cycles, such as lists of primitive literals. Full evaluator
monotonicity, determinism, and a small-step connection remain future work.

## Host Boundary

Pure `--eval` is filesystem-free and rejects `import` with an `eval error:`.

`--eval-imports` is the explicit host IO lane:

- supports relative `./...` and `../...` path imports;
- lexically normalizes `.` and `..` segments for host import reads and
  recursion detection;
- reads imported files through `IO.FS.readFile`;
- parses, validates, desugars, core-validates, evaluates, then reifies
  representable imported values;
- can apply immediately imported closures when the argument and result are
  representable;
- rejects bare imported functions because closures cannot be reified yet;
- rejects angle, home, absolute, store, network, and search-path imports.

Path values are inert text in pure evaluation. They do not check existence,
normalize, copy to the store, or resolve angle paths.

The chosen host-effect direction is a host-aware import layer that keeps
reifying simple values while adding narrow host-only paths for closures.
`CoreEval` should remain filesystem-free.

## Test Snapshot

The current committed e2e manifests cover:

- `e2e/manifest.txt`: 40 pass, 3 parse-fail, 9 validation-fail.
- `e2e/desugar-manifest.txt`: 8 pass, 1 validation-fail.
- `e2e/eval-manifest.txt`: 48 pass, 20 eval-fail.
- `e2e/import-manifest.txt`: 6 pass, 5 eval-fail.
- `e2e/fuel-manifest.txt`: 1 eval-fail.
- `e2e/fuel-low-manifest.txt`: 3 eval-fail.
- `e2e/fuel-success-manifest.txt`: 3 pass.
- `e2e/fuel-high-manifest.txt`: 3 pass.
- `e2e/core-validation-manifest.txt`: 1 core-fail.
- `e2e/json-manifest.txt`: 1 pass.

The pinned external corpus currently has 23 pass cases and no expected
non-pass blockers. Use `./e2e/external-summary.sh` to summarize the external
manifest before and after adding rows.

## Main Risks

1. The parser is broad but still has a large expression-level `partial` island.
2. Host imports are eager and value-only; imported closures still fail.
3. Relative host import paths are normalized only lexically; symlink and
   canonical filesystem identity are not modeled.
4. The core still contains surface-like forms (`with`, `assert`, selection
   defaults for dynamic paths) that should be lowered or justified before large
   preservation proofs.
5. Fuel monotonicity is still restricted to primitive literal, primitive unary,
   and primitive binary proof harnesses; full evaluator monotonicity,
   determinism, and small-step semantics are unproven.
6. External corpus coverage is green for the first pinned set, but still small
   relative to real nixpkgs.
