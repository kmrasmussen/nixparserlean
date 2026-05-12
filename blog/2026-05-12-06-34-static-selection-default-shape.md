# Static Selection Default Shape

Static selection defaults now have a checked lowering-shape theorem.

The desugarer already lowered static non-empty selection defaults away from the
core `select` default branch:

```lean
ifThenElse (hasAttr base path) (select base path none) default
```

This ticket factors that branch through `lowerSelectDefault` and proves
`lowerSelectDefault_static_nonempty_selection_default_shape`. The theorem is
deliberately restriction-aware: it assumes `staticAttrPath? path = true`, which
means the desugared core path is static and non-empty.

This is not full evaluator preservation. It does not prove that every lowered
program evaluates identically to the old core select-default branch, and it
does not cover dynamic selection defaults. It pins down the exact core shape
used by the static lowering so later preservation work has a stable lemma to
build on.
