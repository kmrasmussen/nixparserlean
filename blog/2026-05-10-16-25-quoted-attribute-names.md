# Static quoted attribute names

Nix attribute paths are not limited to bare identifiers. Real code often uses
quoted names for keys that contain punctuation:

```nix
{
  "foo-bar".nested = 41;
}
```

The parser now accepts static quoted attribute-name segments in the places that
already consume `AttrPath`: bindings, attribute selection, and attribute
existence tests.

```nix
attrs."foo-bar".nested
attrs.plain ? "child-name"
```

This intentionally does not model dynamic attribute names yet. A quoted segment
is accepted only when it contains plain text. Interpolated names such as
`${name}` need an AST that can represent dynamic path parts, not just `List
String`, and that deserves its own design step.

The immediate gain is real-world coverage without muddying the semantic model.
Static quoted keys become ordinary `AttrPath` parts today; dynamic keys remain
visible as the next boundary to cross.
