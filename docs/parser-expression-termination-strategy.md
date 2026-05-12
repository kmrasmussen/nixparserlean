# Parser Expression Termination Strategy

The expression parser is the largest remaining `partial` island. It is a
handwritten recursive-descent parser with precedence levels, backtracking, and
recursive calls through `ParserState`, so Lean cannot infer termination from a
simple structural argument.

## Chosen Strategy

Use explicit parser fuel for the expression parser first.

The initial fuel should be derived from the remaining input length at the public
entry point, as the lexer helpers already do. Recursive expression calls receive
a smaller fuel value at expression-entry boundaries. Operator loops should use
their own input-length fuel wrappers where the loop consumes an operator token
before recurring.

This is a proof-friendly intermediate shape. It is not the final ideal, but it
removes opacity incrementally while keeping the current parser architecture.

## Options Compared

### Explicit Parser Fuel

Pros:

- mechanical to review one parser level at a time;
- matches the successful `takeWhileGoFuel` and `anglePathGoFuel` pattern;
- preserves current `ParserState` and source-position diagnostics;
- gives a clear failure mode if a bug stops consuming input.

Cons:

- adds a fuel parameter to many mutually recursive parser functions;
- fuel exhaustion is a termination guard, not a user-facing grammar error;
- later proofs may still want structural recursion over a better parser model.

This is the recommended near-term path.

### `decreasing_by` On Input Length

Pros:

- avoids explicit fuel in parser signatures;
- states the real termination argument directly.

Cons:

- every recursive call must prove the new `ParserState.remaining.length` is
  smaller;
- backtracking and calls that only skip space make proofs noisy;
- parser error-position preservation becomes harder to review together with
  proof plumbing.

Use this later for isolated helpers once the fuel-bounded parser shape has
stabilized.

## Error Position Policy

Parser fuel must not change normal diagnostics. For valid input and ordinary
parse failures, the returned `ParserState.pos` should be the same as today.
Fuel exhaustion is only acceptable for internal non-consuming recursion bugs or
inputs larger than the chosen conservative bound. The public default should be
large enough that repo fixtures do not encounter parser fuel exhaustion.

## First Implementation Ticket

Draft follow-up ticket:

**Fuel-Bound ParseAdd And ParseMul Loops**

- Add internal `parseAddLoopFuel` and `parseMulLoopFuel` helpers in
  `NixParserLean/Parser.lean`.
- Size each loop fuel from `st.remaining.length`.
- Keep public `parseAdd` and `parseMul` signatures unchanged.
- Preserve existing parse output and source positions.
- Run the default parser manifest and external corpus manifest.

This scope is narrow because additive and multiplicative loops are
left-associative, local, and do not need to change lambda, selection, list, or
attribute-set recursion.

## Non-Goals

- No full parser conversion in one ticket.
- No parser-combinator replacement.
- No user-facing `--parser-fuel` flag until there is a real diagnostic need.
