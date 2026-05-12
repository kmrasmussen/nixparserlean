# TICKET-0074: External Corpus Hash Enforcement

## Problem
The external manifest documents optional `sha256` comments, but the runner
currently ignores them.

## Goal
Teach the external corpus runner to enforce documented content hashes when
present.

## In Scope
- Parse `# sha256<TAB>cache-name<TAB>hex` comments in the external manifest.
- Verify cached or downloaded content against the hash.
- Produce clear failures for mismatches.
- Add a small runner test or fixture if practical.
- Update external corpus docs.

## Out of Scope
- Requiring hashes for every row immediately.
- Changing ordinary flake checks.
- Switching away from the current manifest format.

## Acceptance Criteria
1. Hash comments are enforced when present.
2. Mismatch diagnostics are stable.
3. Existing external manifest passes.
4. Runner tests or e2e coverage demonstrate hash behavior.
