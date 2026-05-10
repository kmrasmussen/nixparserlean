# Comments are whitespace

The parser now treats Nix comments as whitespace. That means `#` line comments
and `/* ... */` block comments can appear anywhere ordinary whitespace can
appear: between bindings, inside lists, and around values.

This is a small change, but it is the kind of detail that makes the parser feel
less like a toy. It also keeps comments out of the AST. For this project, that
is the right first choice: the current model is about executable Nix structure,
not source-preserving formatting.

There is still an interesting choice waiting here. An editor, formatter, or
round-tripping parser would need comment nodes or trivia ranges. A semantics
model probably should not. For now the AST stays focused on expressions and
bindings, and source trivia remains a lexer concern.
