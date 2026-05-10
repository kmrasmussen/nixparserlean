# String interpolation enters the AST

Quoted strings are no longer just raw text.

The AST now represents a string as a list of parts:

```lean
inductive StringPart where
  | text : String -> StringPart
  | interpolation : Expr -> StringPart
```

That means a plain string like `"hello"` still has a small representation, but a
real Nix string can carry embedded expressions:

```nix
"${pkgs.hello}/bin/hello-${version}"
```

The parser now splits that into three pieces: an interpolation for
`pkgs.hello`, a text segment for `/bin/hello-`, and an interpolation for
`version`. Interpolations parse through the normal expression parser, so the
contents are not a second, weaker language bolted onto strings.

Validation also follows the new shape. Text parts are inert, while interpolation
parts validate the expression they contain. That keeps the existing parse /
validate split intact: strings can now contain trees, and those trees still go
through the same semantic checks as any other expression.

This is the first step toward real-world Nix string coverage. It does not yet
handle indented strings or every escape rule, but the important AST decision is
in place: strings are structured syntax, not just bytes between quotes.
