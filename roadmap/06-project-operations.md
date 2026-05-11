# Project Operations Roadmap

The project now has enough moving parts that operating discipline matters.
This file records how roadmap work should turn into tickets and commits.

## Ticket Policy

Use `.tickets/` for durable work:

- semantic milestones;
- proof targets;
- corpus blockers;
- parser infrastructure;
- host effect design;
- testing infrastructure.

Avoid tickets for tiny typo/doc fixes unless they are part of a larger
roadmap refresh.

Each substantial ticket should include:

- `## Plan`;
- `## Resolution`;
- verification evidence;
- status set to `completed` when done;
- a blog note for meaningful project changes.

## Commit Shape

Keep commits reviewable:

- one ticket or one narrow roadmap/doc chunk per commit;
- fixtures beside implementation;
- docs/blog beside behavior changes;
- no unrelated worktree cleanup.

Direct push to `master` should only happen when explicitly requested in the
active task. Local commits are acceptable for significant completed chunks.

## Test Policy

Minimum gates:

- Lean-only changes: `nix develop --command lake build`.
- Parser/surface validation: default manifest.
- Desugar/core validation: desugar and core-validation manifests.
- Evaluation: eval manifest plus fuel manifests when fuel or recursion is
  touched.
- Host imports: import manifest.
- CLI/JSON/flake changes: `nix flake check`.

High-confidence gate:

```sh
nix flake check
```

External corpus gate when parser coverage changes:

```sh
cargo run --manifest-path e2e/runner/Cargo.toml -- \
  --manifest e2e/external-manifest.txt
```

## Documentation Policy

Keep these aligned:

- `docs/core.md` for core/eval behavior.
- `docs/parser.md` for grammar and ambiguity decisions.
- `docs/testing.md` for manifest and flake coverage.
- `docs/import-and-path-boundary.md` for host effects.
- `docs/partial-and-fuel.md` for termination and fuel debt.
- `flagged.md` for active caveats.
- `roadmap/` for future work.

When implementation changes behavior, update the relevant docs in the same
commit unless the doc work is intentionally split and ticketed.

## Blog Policy

Blog notes are useful project memory. Add one for:

- language feature support;
- evaluator semantic policy;
- proof or totality milestones;
- corpus ratchet milestones;
- roadmap resets.

Do not write a blog note for every tiny typo or manifest note update.

## Roadmap Maintenance

Revisit this folder after every 3-5 completed tickets or whenever the external
corpus blocker profile changes.

Good roadmap updates should:

- remove completed milestones;
- add the next concrete ticket candidates;
- keep current-state facts accurate;
- narrow or remove stale caveats.

## Suggested Next Tickets

1. External corpus blocker ratchet: spaced dynamic selection.
2. Refresh stale docs after path/fuel/validator work.
3. Quoted inherit names.
4. Restricted static attrset desugar-core-validation theorem.
5. Fuel monotonicity for literals and binary expressions.
6. Imported function diagnostic fixture.
7. Desugar walk explicit fuel.
