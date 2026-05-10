# Lambda parameters become semantic facts

The validator now rejects duplicate entries in destructured lambda parameters:

```nix
{ a, a }: a
```

This is a small check, but it matters for the direction of the project. Lambda
parameters are not just syntax; they introduce names into a scope. If the parser
accepts duplicate formal names without complaint, later desugaring and scope
analysis have to either preserve an impossible surface shape or silently choose
which binding wins.

The implementation keeps this in validation rather than parsing. The parser's
job remains to recognize the surface form and build the AST. The validator then
turns that tree into a language fact: a parameter set names each formal at most
once.

The smoke corpus now includes the duplicate-parameter case as an expected
validation failure. That gives the next phase of lambda work a firmer base:
aliases, defaults, and future scope modeling can rely on parameter entries being
unique before they are desugared.
