# Angle Search Path Design

Angle paths are now documented as an explicit host-boundary feature rather than
an ambient dependency on the developer machine.

The proposed shape is a repeatable `--search-path NAME=PATH` option for the
`--eval-imports` lane. The first component inside `<...>` selects the mapping,
and any remaining components are joined below the mapped directory. That keeps
future `<nixpkgs/lib/default.nix>` support deterministic enough for fixtures
without requiring `NIX_PATH`, network fetchers, or store realization.

The important boundary remains unchanged: pure `CoreEval` does not learn about
the filesystem. Angle imports would resolve in the host import layer, then flow
through the same parse, validation, desugar, core validation, evaluation, and
reification pipeline as relative imports.

The current rejection behavior is still tested, so the design does not weaken
today's semantics. It just records the next implementation slice in a way that
can be exercised entirely with repo-local fixtures.
