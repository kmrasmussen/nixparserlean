# Total Validator Fuel

The surface and core validators no longer use `partial`.

Instead of trying to prove the full mutual AST termination argument in one
step, both validators now use explicit validation fuel. Each recursive descent
through expressions, string parts, lambda parameters, parameter defaults,
attribute paths, or bindings receives a smaller fuel value. Empty lists still
validate at any fuel.

The public validators use a large internal default fuel, so this is not a new
CLI policy. It is a termination device that lets Lean accept the validators as
ordinary total definitions while preserving the existing parser, semantic, and
core error classifications.

This is not the final proof story. A later pass can replace the fuel with a
structural measure over the AST. But the broad validator `partial` island is
gone, and the remaining `partial` debt is now more sharply located in parser,
desugaring, and evaluation.
