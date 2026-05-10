# Arithmetic operators join the table

The parser now handles the ordinary arithmetic operators that were still
missing from the expression stack:

```nix
6 * 7
84 / 2
product - quotient
```

This keeps `+` at the additive level and adds a tighter multiplication level
for `*` and `/`. Subtraction lives next to addition, while unary negation still
binds more tightly.

Division required one small path parsing adjustment. Absolute paths continue to
start with `/` when another non-space character follows it, so `import /path`
still parses as function application to a path. A spaced slash can now be seen
as the division operator, which is the form the smoke fixture uses.
