# Inert Path Values

Path literals now evaluate as values instead of stopping at a placeholder
error. The evaluator represents them as inert path text: no filesystem access,
normalization, store copy, or angle-path lookup happens in pure `--eval`.

That keeps the import boundary intact. Pure evaluation still rejects `import`
with an `eval error:`, while `--eval-imports` remains the host IO lane for
relative local imports. The host layer now also knows how to reify imported
path values, so an imported file can return an attrset containing a path
without forcing that path to mean "read this file".

The new fixtures cover relative, absolute, home, angle, and store-like paths as
values. They also keep unsupported absolute, home, and angle imports classified
as `eval-fail`, which is the important distinction: paths can be values without
every path becoming an import target.
