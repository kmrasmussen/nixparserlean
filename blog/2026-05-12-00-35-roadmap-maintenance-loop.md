# Roadmap Maintenance Loop

The roadmap now has a small maintenance loop instead of relying on memory.

`roadmap/06-project-operations.md` includes the closing checklist: mark the
ticket completed, update the roadmap and behavior docs, add a blog note for
significant work, run the relevant gate, and commit only that ticket's files.
It also records how future tickets should be generated from active roadmap
milestones.

There is one small helper script: `./scripts/open-tickets.sh`. It prints any
non-completed `.tickets` entries, or `all tickets completed` when the backlog is
closed. That is enough operational support for now without replacing the
existing `.tickets` tracker or adding CI automation.
