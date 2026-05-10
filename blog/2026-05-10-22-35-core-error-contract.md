# Core errors join the runner contract

Core validation now has an explicit e2e outcome: `core-fail`.

Keeping `core error:` separate from surface `semantic error:` is useful. The
surface validator rejects invalid Nix syntax and binding structure before
desugaring. Core validation protects invariants of the smaller language after
desugaring, and later proof work will care about that boundary.

The Rust runner now classifies first-line stderr prefixes like this:

```text
parse error     -> parse-fail
semantic error  -> validation-fail
core error      -> core-fail
eval error      -> eval-fail
```

There is also a tiny CLI smoke mode that constructs an invalid core selection
and sends it through `CoreValidate`. That keeps the contract covered without
inventing a source Nix fixture that should never parse to invalid core.

This is small infrastructure, but it removes an ambiguity that would otherwise
turn the first real core-validation failure into an unhelpful runner mismatch.
