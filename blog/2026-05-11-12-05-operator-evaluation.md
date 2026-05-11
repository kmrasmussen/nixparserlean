# Operator Evaluation Catches Up

The parser has had a broader operator table than the evaluator for a while.
That gap is smaller now.

The evaluator now handles:

- list concatenation with `++`;
- shallow attrset update with `//`;
- numeric comparisons over integers, floats, and mixed integer/float operands;
- float arithmetic and mixed integer/float arithmetic.

The policy is intentionally simple. Integer-only arithmetic keeps returning
integer values. If either operand is a float, the evaluator computes with Lean
`Float` and stores the result as `Float.toString`. That is not a final numeric
formalization, but it is a clear execution policy and enough to stop treating
ordinary float arithmetic as unsupported.

The new fixtures cover both success and failure paths. `++` rejects non-list
operands, `//` rejects non-attrsets, and division by zero remains an
`eval error:` for floats as well as integers.
