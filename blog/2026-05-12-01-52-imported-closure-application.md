# Imported Closure Application

The host import lane can now handle the first imported-function success case.

Bare imported functions still cannot be reified into core syntax, so
`import ./function.nix` remains an expected eval failure. But an immediate
application such as `import ./function.nix 41` can now run in `HostEval.lean`:
the imported file is evaluated through the explicit host layer, the closure is
applied there, and the representable result is reified for the final pure pass.

This is intentionally narrow. It keeps filesystem behavior out of `CoreEval`
and does not claim full lazy import semantics. The next host-effect widening
target is imported applications whose arguments depend on the importing
expression's local environment.
