# Filling in the operator table

The expression parser now covers the next set of everyday Nix operators.

Binary operators gained constructors for inequality, comparisons, implication,
and list concatenation:

```nix
1 != 2
1 < 2
2 <= 2
3 > 2
3 >= 3
condition -> result
[ 1 ] ++ [ 2 ]
```

There is also a small unary operator layer for boolean negation and negating
non-literal expressions:

```nix
!false
-(1 + 2)
```

The precedence stack grew instead of flattening the grammar. Implication sits
above `parseOr` and is right-associative. Equality now handles both `==` and
`!=`. Comparisons have their own level. Attribute-set update still sits above
comparisons, list concatenation sits above update, and `+` keeps its existing
tighter level.

One useful bug fell out of the new fixture: angle paths were too eager. Because
`<` started a path unconditionally, `1 < 2 ... >` could be misread as applying
`1` to an angle path. Angle paths now require a non-whitespace character after
`<`, and whitespace inside an angle path is rejected. That keeps `<nixpkgs>`
working while letting spaced comparison syntax parse correctly.
