# Core Static Name Invariant

Core validation now rejects empty static binding names before evaluation or
proof work sees them.

The invariant is small but useful: evaluator and theorem work can treat static
binding names as real names, while dynamic attribute paths remain the explicit
place for computed names. The core-validation smoke fixture now constructs an
invalid core attrset with an empty static name and verifies that the runner
classifies the failure as `core-fail`.

This is still an executable contract rather than a theorem. The next proof step
is showing that the relevant surface/desugar slices cannot produce this invalid
core shape when their source syntax is well-formed.

