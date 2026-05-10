# Recursive Attrsets Evaluate

Recursive attribute sets are one of the places where Nix stops looking like a
plain record language. Attributes can refer to siblings, including siblings that
appear later in the set:

```nix
rec {
  a = b + 1;
  b = 41;
}.a
```

The evaluator already had a conservative thunk environment for recursive `let`
bindings. This change reuses that mechanism for static recursive attrsets: the
attributes are evaluated under an environment that contains thunks for the whole
set, so sibling lookup can resolve through the recursive scope.

The supported fragment stays intentionally narrow. Dynamic attribute bindings
still fail at evaluation time, and recursive cycles are detected as eval errors
instead of being allowed to spin. The thunk representation now carries a context
label, which keeps diagnostics honest: recursive `let` failures still say
`recursive let binding`, while recursive attrset cycles now say
`recursive attribute binding`.

The new eval fixtures cover later sibling lookup, a terminating sibling chain,
self recursion, and mutual recursion. This is not yet a full fixed-point model
of Nix attrsets, but it moves the evaluator into a much more realistic semantic
zone.
