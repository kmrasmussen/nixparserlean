# Parser Expression Termination Strategy

The expression parser now has a concrete termination plan.

The chosen near-term path is explicit parser fuel, derived from remaining input
length, starting with local operator loops. That matches the lexer helper
pattern already used by `takeWhileGoFuel` and `anglePathGoFuel`: keep the public
parser shape stable, add a conservative internal bound, and preserve source
positions.

The alternative, proving `decreasing_by` directly on input length, is cleaner in
the final model but too invasive for the current recursive-descent parser. It
forces every parser call to carry proof details about how `ParserState`
shrinks, which is a poor first review chunk while the parser is still growing.

The first implementation slice is intentionally narrow: fuel-bound the
`parseAdd` and `parseMul` loops, run the default and external parser manifests,
and leave lambda/list/attrset recursion untouched.
