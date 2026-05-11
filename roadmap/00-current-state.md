# Current State

This is a factual snapshot of the repository after the completion of
`TICKET-0031`.

## Repository State

- Branch: `master`.
- All tickets through `TICKET-0031` are marked `completed`.
- Recent work completed:
  - inert path values;
  - first desugar soundness slice;
  - evaluator entry-step fuel;
  - total fuel-bounded surface and core validators;
  - low-risk evaluator helper totality.
- The root `flagged.md` contains the active caveats that still matter:
  eager value-only host imports, inert path values, empty attribute path
  proof gap, remaining `partial` islands, unproven fuel semantics, and the
  AGENTS/e2e checklist mismatch.

## Supported Surface Syntax

The parser supports the main expression forms needed by the current smoke and
external corpus:

- literals: integers, floats, strings, indented strings, booleans, null,
  paths;
- lists and attribute sets, including recursive `rec { ... }`;
- `let ... in`;
- identifier lambdas and attrset parameter lambdas;
- parameter defaults, ellipsis, and aliases in both `args@{ ... }` and
  `{ ... }@args` positions;
- `if ... then ... else`, `assert`, and `with`;
- selection, selection defaults, and attribute existence tests;
- function application and parenthesized application arguments;
- `inherit` and `inherit (scope)`;
- static, quoted, and dynamic attribute path parts;
- arithmetic, comparison, boolean, implication, list concat, and attrset
  update operators.

The parser remains handwritten and broad use of `partial` remains in
`Parser.lean` and `Parser/Basic.lean`.

## Validation Layers

Surface validation checks source-level semantic invariants:

- duplicate bindings and prefix conflicts for static paths;
- duplicate `inherit` names;
- duplicate attrset lambda parameter entries;
- lambda alias name conflicts;
- recursive validation of expressions embedded in string interpolation and
  dynamic attribute paths.

Core validation checks post-desugaring invariants:

- duplicate static binding names at each core binding level;
- non-empty dynamic assignment paths;
- non-empty selection and attribute-existence paths;
- valid expressions inside dynamic paths and string interpolation;
- duplicate core lambda parameter entries and alias conflicts.

Both validators are now total definitions using explicit validation fuel:
`defaultValidationFuel = 100000`.

## Desugaring

Surface syntax lowers into `NixParserLean.Core.Expr`.

Current important behavior:

- dotted static paths lower into nested static core attrsets;
- sibling static paths are merged through total fuel-bounded merge helpers;
- dynamic attribute paths remain explicit `dynamicAssign` nodes;
- bare inherit lowers to `inheritAssign`;
- scoped inherit lowers to static selections;
- empty lowered static paths are rejected with
  `desugar error: empty attribute path`.

The proof surface currently includes lemmas about static path top-level names,
nested static path shape, empty-path rejection, and merge behavior. The
recursive surface-to-core walk is still `partial`.

## Evaluation

The pure evaluator supports a sizeable but intentionally bounded core fragment:

- primitive values, lists, attrsets, strings and interpolation;
- inert path values;
- recursive `let` and recursive static attrsets via thunks;
- cycle detection for recursive bindings;
- identifier lambdas and attrset lambdas with defaults, ellipsis, and aliases;
- `with` lookup fallback;
- dynamic attribute construction and selection in non-recursive scopes;
- arithmetic, comparisons, equality, booleans, list concat, and attrset update.

Fuel is now an entry-step budget: every entry into `Core.Eval.eval` spends one
fuel step. Structural walkers spend fuel only when they evaluate contained
expressions. This is deterministic and tested, but not yet connected to a
separate small-step semantics.

## Host Boundary

Pure `--eval` is filesystem-free and rejects `import` with an `eval error:`.

`--eval-imports` is the explicit host IO lane:

- supports relative `./...` and `../...` path imports;
- reads imported files through `IO.FS.readFile`;
- parses, validates, desugars, core-validates, evaluates, then reifies
  representable imported values;
- rejects imported functions because closures cannot be reified;
- rejects angle, home, absolute, store, network, and search-path imports.

Path values are inert text in pure evaluation. They do not check existence,
normalize, copy to the store, or resolve angle paths.

## Test Snapshot

The current committed e2e manifests cover:

- `e2e/manifest.txt`: 36 pass, 3 parse-fail, 8 validation-fail.
- `e2e/desugar-manifest.txt`: 6 pass, 1 validation-fail.
- `e2e/eval-manifest.txt`: 41 pass, 20 eval-fail.
- `e2e/import-manifest.txt`: 3 pass, 3 eval-fail.
- `e2e/fuel-manifest.txt`: 1 eval-fail.
- `e2e/fuel-low-manifest.txt`: 2 eval-fail.
- `e2e/fuel-success-manifest.txt`: 2 pass.
- `e2e/core-validation-manifest.txt`: 1 core-fail.
- `e2e/json-manifest.txt`: 1 pass.

The pinned external corpus currently has 10 pass cases and 5 expected
parse-fail cases. Current blocker categories:

- `spaced-dynamic-selection`: 2 cases.
- `quoted-inherit-name`: 1 case.
- `path-argument-dot-file`: 1 case.
- `indented-string-escape`: 1 case.

## Main Risks

1. The parser is broad but still partial and not yet proven terminating.
2. Desugaring is still too close to the surface language; the core should
   become smaller before serious evaluator proofs.
3. Host import semantics are eager and value-only.
4. Path values are useful but deliberately weaker than Nix store path
   semantics.
5. Fuel is now a step policy, but monotonicity and determinism are not proven.
6. Some docs still need routine freshness checks after rapid feature work.
