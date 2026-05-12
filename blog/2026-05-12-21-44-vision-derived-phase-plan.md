# Vision-Derived Phase Plan

The roadmap now has a dedicated vision document.

The important correction is that the phase plan should not read like vague
workstream labels. It should describe capabilities the project gains on the way
to becoming a Lean-backed semantic lens for Nix.

`roadmap/VISION.md` now states the product shape, proof shape, strategic
principles, non-goals, and a north-star `nixparserlean explain ./default.nix
--json` demo. The vision emphasizes real Nix input, source-positioned syntax,
semantic validation, explicit core, pure and host-aware evaluation lanes,
analysis artifacts, and checked theorems.

`roadmap/01-phase-plan.md` now derives from that vision. The phases are:

1. Read Real Nix.
2. Explain Nix Structure.
3. Explain Nix Semantics.
4. Stabilize The Core.
5. Check The Model.
6. Retire Termination Debt Where It Affects The Lens.
7. Make The Workflow Durable.

Each phase names the vision link, user-visible capability, concrete tickets,
and exit criteria. That should make future roadmap conversations less abstract:
if a ticket does not advance one of those capabilities, it probably does not
belong in the next wave.
