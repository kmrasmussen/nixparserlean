# Dynamic Attribute Evaluation

Dynamic attribute names were already visible in the parser, the surface AST, and
core desugaring:

```nix
let key = "name"; in
{ ${key} = 41; }.name
```

Evaluation was the missing layer. This change gives the evaluator a conservative
dynamic attribute fragment: dynamic path parts are evaluated into strings,
non-recursive attrset bindings can insert those names, and selection can use the
same evaluated path logic.

The fragment is intentionally narrow. Interpolation inside a dynamic attribute
name must evaluate to a string. That supports `${key}` and quoted names like
`"prefix-${key}"`, while rejecting unsupported values with a clear eval error
instead of guessing at full Nix coercion semantics.

Recursive attrsets with dynamic bindings remain unsupported for now. Dynamic
`let` bindings also remain unsupported, which keeps this slice focused on
ordinary attrset construction and lookup.

The new smoke fixtures cover dynamic binding, dynamic selection, quoted
interpolated names, and the non-string interpolation failure case. The existing
parser fixture for dynamic attr names now also evaluates successfully by manual
check, returning `3`.
