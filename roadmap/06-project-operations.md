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

- keep the strategy visible before the ticket list;
- demote completed waves into historical context;
- add or reorder the next concrete ticket candidates by workstream;
- keep current-state facts accurate;
- narrow or remove stale caveats.

Maintenance checklist for closing a ticket:

1. Set `.tickets/TICKET-XXXX/ticket-state.json` to `completed`.
2. Update the roadmap file that named or implied the work.
3. Update docs that describe the changed behavior, test lane, proof surface, or
   known limitation.
4. Add a blog note for significant parser, evaluator, proof, corpus, or roadmap
   movement.
5. Run the relevant gate from the test policy above.
6. Commit only that ticket's files.

Open-ticket command:

```sh
./scripts/open-tickets.sh
```

The command prints non-completed tickets as `TICKET-XXXX<TAB>status`, or
`all tickets completed` when the backlog is closed.

When generating future tickets from the roadmap, keep the ticket narrow enough
to land in one reviewable commit. A good ticket title names the artifact and
the smallest useful behavior, for example `Fuel-Bound ParseAdd And ParseMul
Loops`. The ticket body should include a problem, goal, in-scope list,
out-of-scope list, and acceptance criteria with the expected e2e or build gate.

## Suggested Next Tickets

The active staging list is
[`07-next-ticket-candidates.md`](07-next-ticket-candidates.md). Refresh that
file from `roadmap/01-phase-plan.md` and the milestone files after each
maintenance pass, then turn one candidate at a time into a concrete `.tickets`
entry.
