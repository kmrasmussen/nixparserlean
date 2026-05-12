# Determinism Modulo Fuel

The proof roadmap needed a named determinism target before the restricted
evaluator subset grows again. I added same-fuel determinism theorems for the
current fuel harnesses in `NixParserLean.CoreEval.Fuel`.

The theorem shape is simple: if the same harness run with the same fuel
succeeds with two results, those results are equal. Because the harnesses are
currently executable functions, the proof is just function determinism. That is
not deep yet, but it gives the roadmap an exact checked statement to preserve
when this area eventually grows into a relation or a proof-friendlier evaluator
model.

The scope remains intentionally narrow. These theorems cover the restricted
literal, unary, binary, list-item, and non-recursive static attrset harnesses.
They do not claim full determinism for thunks, recursive environments, host
imports, or the production evaluator mutual recursion.
