# Docs Freshness

The roadmap reset made the documentation contract stricter: contributor
guidance should point at the actual verification surface, and caveats should
name active roadmap files instead of stale paths.

This refresh updates the high-traffic docs after the path, fuel, validator, and
external-corpus work:

- `docs/core.md` now lists `Value.path` and no longer says path values are
  unsupported by the evaluator.
- `docs/testing.md` names the fuel, JSON, import, CLI, and default smoke gates
  that `nix flake check` actually runs.
- `AGENTS.md` delegates the full gate matrix to `docs/testing.md` and calls out
  `nix flake check` for broad behavior changes.
- `docs/README.md` links the active root `roadmap/` folder.
- `flagged.md` drops the resolved AGENTS gap and points the remaining caveats
  at root roadmap files and current tickets.

No Lean behavior changed here. The value of the change is that docs now match
the code and test harness closely enough to guide the next ticket without
forcing another archaeology pass.

