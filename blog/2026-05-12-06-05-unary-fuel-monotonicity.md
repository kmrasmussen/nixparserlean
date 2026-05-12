# Unary Fuel Monotonicity

The evaluator fuel proof surface has widened by one expression shape.

The original checked theorem covered primitive literals and binary expressions
whose operands are primitive literals. The new
`evalLiteralUnaryBinarySubsetWithFuel_monotone` theorem adds unary expressions
over primitive literal operands while keeping the proof harness total and
environment-free.

This is still intentionally narrow. It does not try to prove anything about
closures, thunks, host imports, selections, conditionals, lists, or attrsets.
The value is that the pattern is now clear for the next widening step: add a
recursive walker such as lists of primitive literals, then move to
non-recursive static attrsets once the list case is boring.

The e2e fuel manifests now include a unary fixture as well. `! false` fails at
fuel one, succeeds at fuel two, and remains stable with extra fuel.
