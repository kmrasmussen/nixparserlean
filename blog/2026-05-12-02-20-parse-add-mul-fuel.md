# Parse Add And Mul Fuel

The parser totality program has its first expression-level slice.

`parseAdd` and `parseMul` still keep their public signatures, but their
left-associative operator loops now delegate to top-level total helpers:
`parseAddLoopFuel` and `parseMulLoopFuel`. The fuel is sized from the remaining
input after the left operand is parsed, matching the strategy chosen for the
expression parser.

This does not remove the whole expression parser `partial` cluster. It does
make the additive and multiplicative loops transparent to Lean's termination
checker, which gives the next parser-totality tickets a pattern to copy.
