# Next Ticket Candidates

This file is intentionally not a ticket tracker. It is the staging area for the
next `.tickets` wave. Turn one candidate at a time into a real
`.tickets/TICKET-XXXX` entry when work begins.

## Recommended First Wave

### Host Value Slots For Imported Closures

Roadmap source: [05-host-effects.md](05-host-effects.md) and
`docs/host-effect-evaluator-shape.md`.

Goal: let `--eval-imports` carry an imported closure far enough for the
importing file to apply it, without adding filesystem behavior to `CoreEval`.

Likely scope:

- add an internal host value slot or host environment representation in
  `HostEval.lean`;
- keep current reification for representable imported values;
- add a repo-local fixture where an imported function is applied;
- preserve or narrow the existing imported-function rejection fixture.

Gate: `lake build`, import manifest, eval manifest.

### Fuel-Bound `parseAdd` And `parseMul` Loops

Roadmap source: [04-proofs-and-totality.md](04-proofs-and-totality.md) and
`docs/parser-expression-termination-strategy.md`.

Goal: convert the first expression parser operator loops to total
fuel-bounded helpers while keeping public parser signatures stable.

Likely scope:

- add `parseAddLoopFuel` and `parseMulLoopFuel`;
- size loop fuel from `ParserState.remaining.length`;
- preserve existing parse output and error positions.

Gate: `lake build`, default parser manifest, external manifest.

### Unary Primitive Fuel Monotonicity

Roadmap source: [04-proofs-and-totality.md](04-proofs-and-totality.md).

Goal: widen the checked fuel monotonicity proof from literals/binary expressions
to unary expressions over primitive literals.

Likely scope:

- extend the total proof harness in `CoreEval.lean`;
- prove success is preserved with extra fuel;
- document exclusions.

Gate: `lake build`, fuel manifests, eval manifest.

### Relative Import Path Normalization Policy

Roadmap source: [05-host-effects.md](05-host-effects.md).

Goal: decide and test how `--eval-imports` handles aliases such as
`./nested/../file.nix`, especially for recursion detection.

Likely scope:

- document whether normalization is for recursion detection, file reads, both,
  or neither;
- add repo-local recursive import alias fixtures;
- keep pure `Value.path` text unnormalized.

Gate: import manifest.

### Second External Corpus Wave

Roadmap source: [02-parser-and-corpus.md](02-parser-and-corpus.md).

Goal: add another pinned set of real nixpkgs files and classify the next
blockers.

Likely scope:

- add immutable URL rows to `e2e/external-manifest.txt`;
- use optional `sha256` comments for refresh intent;
- update `./e2e/external-summary.sh` output in docs/blog;
- create follow-up tickets from any non-pass blocker categories.

Gate: external manifest. Do not add this to ordinary flake checks.

## Second Wave

### Comment And Whitespace Scanner Totality

Goal: move `skipLineComment`, `skipBlockComment`, and `skipSpace` off
`partial` with input-length fuel.

Gate: `lake build`, default parser manifest.

### String Scanner Totality

Goal: convert quoted and indented string scanning to fuel-bounded helpers while
preserving interpolation and escape behavior.

Gate: `lake build`, default parser manifest, external manifest.

### Static Selection Default Preservation Theorem

Goal: prove the TODO around static selection-default lowering in
`Desugar.lean`.

Gate: `lake build`, desugar manifest.

### Core `with` Decision

Goal: decide whether `with` remains a permanent core form or lowers into an
explicit environment operation.

Gate: desugar manifest, eval manifest, docs/core.md update.

### Angle Search Path Prototype

Goal: implement the documented `--search-path NAME=PATH` host import shape with
repo-local fixtures.

Gate: import manifest; current no-search-path angle rejection remains tested.
