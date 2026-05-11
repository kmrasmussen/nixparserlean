# Parser Helper Totality

Parser termination is still a large problem, but two lexer helpers no longer
need `partial`.

`takeWhileGo` and `anglePathGo` now delegate to fuel-bounded helpers sized from
the remaining input length. The wrappers preserve the public helper shape and
the same `ParserState` bumping behavior, so source offsets, lines, and columns
stay stable.

The default parser manifest still reports the expected parse and validation
failures only, and the pinned external corpus remains fully passing.

The remaining parser totality work is still substantial: comment skipping,
whitespace skipping, string scanning, and then the expression parser.

