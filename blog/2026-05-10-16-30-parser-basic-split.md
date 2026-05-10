# Parser Basic Split

The parser had reached the point where size was starting to matter. It was not
unreadable, but `Parser.lean` mixed two different concerns: low-level parser
machinery and the Nix expression grammar.

This change moves the reusable machinery into `NixParserLean.Parser.Basic`:

- parser state and parser result type
- offset-aware parse failures
- whitespace and comment skipping
- token, operator token, identifier, and keyword helpers
- integer and path literal helpers
- string text flushing

The expression grammar stays in `Parser.lean`. That boundary is deliberate. The
grammar still has real mutual dependencies between strings, attr paths, binding
lists, lambdas, applications, selections, and special forms. Splitting that too
early would make the code smaller on paper while making changes harder to
follow.

The practical result is that `Parser.lean` dropped from 704 lines to 521 lines,
with 189 lines now living in `Parser/Basic.lean`. More importantly, structured
parse errors now have an obvious future home: the basic parser layer can grow an
error type without forcing every grammar function to move at the same time.

No grammar behavior changed in this slice. The full build, parser/desugar/eval
e2e manifests, and flake check all pass.
