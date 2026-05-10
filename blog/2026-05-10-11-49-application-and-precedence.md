# Application and precedence

The parser now has its first expression-precedence layer. That changes the
shape of the project more than the individual syntax forms suggest.

Function application is represented directly:

```nix
f x
```

and it composes with lambdas:

```nix
let
  id = x: x;
in
  id 1
```

The parser also recognizes a small set of common binary operators: `+`, `==`,
`&&`, `||`, and `//`. They are parsed through a precedence stack instead of a
single flat expression rule, so examples like this have real structure in the
AST:

```nix
if true && 1 == 1 || false then "yes" else "no"
```

Parenthesized expressions landed with the same pass:

```nix
(1 + 2) == 3
```

The important detail is not that this is a complete Nix operator table. It is
not. The important detail is that the parser now has a place for precedence to
grow. Selection and application bind tighter than the binary operators, and the
keyword forms still stop cleanly at boundaries like `then`, `else`, and `in`.

The next ambitious step is to decide how much of the real Nix precedence table
to model before adding paths, interpolation, and imports. Those features will
stress the boundary between lexical syntax and expression parsing more than the
forms added so far.
