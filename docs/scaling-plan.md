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

1. Add parser CLI support for `--file`, so large fixtures do not need to travel
   through command-line arguments.
2. Add committed smoke fixtures and a minimal Rust e2e runner.
3. Add expected-failure entries for syntax we know is missing, such as lambdas
   and operators.
4. Add a first external corpus manifest, initially disabled or marked expected
   failure.
5. Extend the parser based on the most common real-world failures.
