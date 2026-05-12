# Relative Import Normalization

The host import lane now has a concrete path identity policy.

`--eval-imports` still only accepts relative `./...` and `../...` imports, but
after joining an import path with the importing file's directory it now
normalizes `.` and `..` segments lexically. That normalized text is used both
for the file read and for the recursive import stack.

This is deliberately not filesystem canonicalization. Symlinks are not
resolved, absolute paths remain unsupported in import position, and pure path
values still keep their parsed spelling. The policy is narrow: make local
relative import aliases deterministic without making `CoreEval` host-aware.

The import manifest now covers both sides of the decision. A simple
`./nested/../target.nix` alias imports successfully, and an alias that points
back to the importing file fails as a recursive import instead of wandering
until the import-depth budget is exhausted.
