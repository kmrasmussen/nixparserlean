# Next Wave Tickets

All existing `.tickets` entries are complete, so the backlog needed a new
frontier.

The next tickets deliberately split the work across three horizons:

- immediate real-Nix parser pressure from the pinned external corpus;
- evaluator depth for operators and path/import semantics that the parser
  already exposes;
- proof-oriented Lean work around total validators, desugaring invariants,
  and semantic evaluation fuel.

The first ticket to pick up should be `TICKET-0024`: parenthesized application
arguments plus clearer lambda diagnostics. It is small enough to review, and
it should make the external corpus failures point at the real next blockers.

The larger bet is that `TICKET-0025` turns real Nix files into a ratchet. The
project should not chase all of nixpkgs blindly, but it should keep a curated
set of pinned files whose expected failures tell us what syntax or semantics
matter next.
