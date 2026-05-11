# Desugar Soundness Slice

The first desugaring soundness step is intentionally small: static attribute
path lowering now has a checked theorem that the lowered binding exposes the
same top-level static core name.

That name is one of the invariants consumed by core validation. It is not full
surface-to-core preservation yet, but it connects a real desugaring behavior
used by fixtures like `attrpath-siblings.nix` to a core-side fact that later
proofs can build on.

This slice also removes the old empty-path fallback. `bindingFromPath` now
returns `Except`, and a statically empty path becomes:

```text
desugar error: empty attribute path
```

Parser-produced attribute paths should make that branch unreachable. The next
proof step is to connect parser or surface validation non-emptiness to this
desugaring helper, then widen from static binding names to full core validation
preservation.
