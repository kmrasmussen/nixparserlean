# Scaling the Nix Parser Exploration

The project should scale along two tracks:

1. Make the Lean parser/model more faithful to Nix.
2. Grow an external corpus that continuously tells us which real-world syntax is
   still missing.

Lean remains the implementation language for the parser and semantic model. A
separate e2e harness can be written in Rust because the harness has a different
job: find files, download fixtures, cache inputs, run the parser as a process,
and summarize failures without complicating the Lean model.

## Layers

### Unit and Golden Tests

Small syntax examples should live in the repository and be easy to review.
These are the tests for features we intentionally support:

- literals and identifiers
- lists and attribute sets
- comments
- `let ... in`
- paths, strings, interpolation, functions, operators, and imports as they land

These fixtures should be stable and committed. They protect behavior while the
parser changes.

### Corpus Tests

Corpus tests should answer a different question: "What does real Nix code do to
this parser today?"

The corpus should start with local fixtures and grow toward downloaded files:

- committed smoke fixtures in `e2e/corpus/smoke`
- cached third-party files in `e2e/cache`
- a manifest of known external sources
- an expected outcome for each case, so unsupported syntax can be tracked
  deliberately instead of making every run red

The important metric is not just pass/fail. The harness should report:

- number of files parsed
- number of expected failures
- number of unexpected failures
- first parse error per file
- syntax categories implied by recurring failures

### Download Strategy

Downloaded corpus files should be cached and reproducible.

The manifest should store a stable name, a URL, and an expected result. Later it
can store hashes. The first harness can use `curl` through a subprocess, which
keeps dependencies low. Once the corpus becomes large, the harness can add:

- content hashes
- refresh modes
- GitHub repository snapshots
- nixpkgs revision pinning
- per-source licenses or provenance notes

### Rust Harness

Rust is a good fit for the e2e layer because it can:

- build the Lean executable once
- run each fixture in a separate process
- enforce timeouts later
- cache downloaded files
- emit concise terminal summaries
- grow into JSON/JUnit output for CI

It should not parse Nix itself. It should only orchestrate inputs and call the
Lean parser.

### CI Shape

CI should eventually have three tiers:

- `lake build`: Lean builds.
- `cargo run -p e2e-runner -- --manifest e2e/manifest.txt`: committed and
  cached corpus behavior is checked.
- scheduled corpus refresh: downloads new sources, reports drift, and does not
  block ordinary development unless expected outcomes are updated.

## Near-Term Milestones

These were the original near-term milestones. They are all complete:

1. ✅ `--file` CLI support so fixtures don't ride on `argv`.
2. ✅ A committed smoke fixture set (`e2e/corpus/smoke/`) and a minimal Rust
   e2e runner with manifest-driven expectations.
3. ✅ Expected-failure entries for currently-missing syntax tracked through
   the `parse-fail`, `validation-fail`, and `eval-fail` expectations.
4. ✅ A first external manifest format (`url` rows in the runner, plus
   `e2e/external-manifest.example.txt`).
5. ✅ Parser surface coverage for lambdas, operator table, attribute paths
   (including dynamic ones), strings (quoted + indented + interpolation),
   `with`, `assert`, `inherit`/`inherit (scope)`, and path literals.
6. ✅ A second pinned external corpus wave, bringing the external manifest to
   23 passing nixpkgs rows with no expected non-pass blockers.

## Current Tracks

Surface coverage is now wide enough that the next gains come from depth, not
breadth:

- **Surface→Core pipeline.** A first desugaring (`Desugar.lean`) lowers
  surface `Expr` into `Core.Expr` with explicit static/dynamic bindings.
  `CoreValidate.lean` enforces post-desugaring invariants. The first
  evaluator (`CoreEval.lean`) handles a sizeable fragment (see `core.md`).
- **Examples as integration tests.** `examples/current-core-showcase` is a
  combined-feature `.nix` file referenced from the eval manifest.
- **Host boundaries.** `HostEval.lean` is the first explicit IO layer: pure
  `--eval` stays filesystem-free, while `--eval-imports` handles relative
  local imports through a separate manifest.
- **Backlog discipline.** `.tickets/` carries durable items that span multiple
  commits, and `flagged.md` records remaining shortcuts that should turn into
  future tickets when they become schedulable.

The medium-term focus is the Lean payoff: replace `partial` with terminating
or fuel-bounded definitions, introduce the first proofs about
desugaring/evaluation, and stretch the corpus to real-world Nix files in
`e2e/eval-manifest.txt` rather than only smoke fixtures.
