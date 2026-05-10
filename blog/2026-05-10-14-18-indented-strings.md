# Indented strings

The parser now recognizes Nix's `'' ... ''` string form.

That matters because embedded shell snippets are everywhere in real Nix code:

```nix
''
echo ${pkgs.hello}
''
```

Indented strings reuse the same structured string representation as quoted
strings. Text remains text, and `${...}` parses as a normal expression
interpolation. That means downstream validation does not need a separate path
for multiline strings: interpolation expressions are still ordinary expression
trees.

This first slice deliberately parses the delimiter and interpolation structure
without trying to model every Nix string normalization rule. Real Nix indented
strings have indentation stripping and special escaping behavior. Those belong
in a follow-up that can be tested directly against the exact semantics. The AST
decision is already in place: both string forms are structured lists of parts.
