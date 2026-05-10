# Docs and Flagged Audit

After closing the ticket backlog, the remaining project notes needed to catch
up with the implementation. Several old caveats had become stale: floats now
parse and evaluate as values, `core error:` has a runner classification, lambda
alias conflicts are checked, JSON output and `--fuel` exist, and host imports
have an explicit `--eval-imports` path.

This pass updates the documentation around the current architecture, CLI,
parser error shape, core evaluator, import boundary, and e2e manifests. It also
rewrites `flagged.md` so it records live shortcuts instead of already-fixed
ones.

The main remaining caveats are now clearer: host imports are eager and
value-only, path values still do not evaluate, `partial` remains the major
proof debt, fuel is configurable but not yet a semantic step counter, and the
repo-local AGENTS checklist under-runs the full flake check.
