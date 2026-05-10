# Structured parse errors

Parser failures now carry structured position data internally.

`ParserM` is no longer just `Except String`; it returns a `ParseError` with
offset, line, column, and message fields. The CLI still prints the familiar
prefix:

```text
parse error at offset 11 (line 2, column 10): expected '=', found '1'
```

That keeps the Rust runner contract stable while making the Lean-side parser
more useful for corpus triage and eventual editor diagnostics.

The parser state now advances line and column counters in `bump`, so all parser
helpers that report through `failAt` inherit the richer source position. A new
unterminated-list fixture keeps one multi-line parse failure in the smoke
suite.
