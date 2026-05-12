# Roadmap Strategy Clarity

The roadmap now says more directly what NixParserLean is trying to become: a
Lean-backed analysis and semantics engine for Nix.

That framing matters. The project is not only a parser, and it should not
claim too early to be a verified replacement for Nix. The useful middle ground
is a semantic lens over real Nix code: parse it, validate it, lower it into an
explicit core, evaluate the pure fragment, isolate host effects, expose useful
analysis artifacts, and grow checked theorems over the parts that have become
stable enough to reason about.

I rewrote the roadmap entry point around strategic pillars: real Nix
legibility, a small explicit core, useful analysis before completeness, named
host-effect boundaries, proofs that follow executable structure, and
reviewable ambition.

The phase plan now orders work by leverage rather than by ticket number. The
next useful center of gravity is analysis artifacts and diagnostics, followed
by corpus discipline, explicit host semantics, core policy decisions, proof
growth, parser totality, and project operations.

The ticket candidate page is also clearer. It now ranks the ready tickets by
workstream and explains why each group matters. Historical ticket waves remain
visible, but they no longer dominate the active roadmap.
