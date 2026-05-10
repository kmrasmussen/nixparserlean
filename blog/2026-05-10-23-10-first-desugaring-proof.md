# First desugaring proof

The desugaring layer now has its first checked invariant.

The new theorem says that if a non-empty attrpath is fully static, then
`bindingFromPath` produces a core binding whose top-level static name is the
same first path segment:

```lean
theorem bindingFromPath_static_top_name
```

This is intentionally small. It connects the static-path detector,
`nestedStaticAssign`, and the core binding shape that `CoreValidate` relies on
when checking duplicate static names.

The proof also forced a useful cleanup: `staticNames?`, `nestedStaticAssign`,
and `bindingFromPath` were marked `partial` even though they are structurally
recursive or non-recursive. Removing that marker makes the definitions more
available to Lean's kernel and starts paying down the proof debt without
changing runtime behavior.

There is plenty left: nested structure, merge behavior, and uniqueness after
desugaring still need proof coverage. TICKET-0020 tracks that next proof slice.
