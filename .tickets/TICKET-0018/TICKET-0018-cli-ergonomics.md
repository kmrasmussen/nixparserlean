# TICKET-0018: CLI Ergonomics — Unknown Flags and Stable Output Format

## Problem
Two related rough edges in `Main.lean`:

1. The flag parser (`readInput`) enumerates every legal pairing of `--file`,
   `--desugar`, and `--eval`. The fall-through silently treats any
   unrecognised arguments as inline Nix source, so `lake exe nixparserlean
   --typo` parses `"--typo"` as `unary .negate (unary .negate (ident
   "typo"))` and prints the `repr`. Flag-name typos succeed silently with
   surprising output.
2. The only output format is `IO.println (repr expr)` / `(repr value)`.
   The `repr` instance is a Lean-source-like debug print that is unstable
   across Lean versions and was not designed as a wire format. Any tool
   consuming the parser's stdout depends on an incidental format.

See `flagged.md` items #10 and #11.

## Goal
Ship a CLI that rejects unknown flags and offers at least one stable
machine-readable output mode.

## In Scope
- A small option parser that walks `args` token-by-token, validates each
  flag, and reports unknown flags with a non-zero exit code.
- `--help` text describing every flag, including any new ones from
  TICKET-0008 / TICKET-0007 follow-ups (e.g. fuel) where applicable.
- A second output mode (`--format json` or `--format sexp`) with a stable
  schema for the surface AST, the core AST, and the eval value.
- Backwards-compatible default: `lake exe nixparserlean ...` without
  `--format` keeps the existing `repr` output.

## Out of Scope
- A full library API; this stays CLI-shaped.
- Source-position reporting in JSON output (depends on TICKET-0008).
- LSP integration.

## Acceptance Criteria
1. `lake exe nixparserlean --typo` exits non-zero with a clear "unknown
   flag" message.
2. `lake exe nixparserlean --help` lists every supported flag.
3. `--format json` produces stable, documented JSON for surface AST, core
   AST, and eval value, exercised by at least one fixture.
4. The runner contract for stderr prefixes (TICKET-0016) is preserved.
