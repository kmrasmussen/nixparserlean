# Semantic Lens Alpha Sprint

The next sprint is deliberately ambitious: all ready tickets from
`TICKET-0061` through `TICKET-0080`.

The sprint is now captured in
`roadmap/08-semantic-lens-alpha-sprint.md`. It groups the 20 tickets into
tracks: semantic artifacts, real corpus discipline, explicit host semantics,
core policy, proof growth, parser totality, and project durability.

The important change is that the sprint is not just a list of tickets. It has a
single outcome: land a first alpha of the semantic-lens vision. By the end,
NixParserLean should have stronger structured diagnostics, JSON failure
contracts, corpus lane discipline, explicit search-path and host-path
boundaries, sharper core policy, wider proof targets, and CI/local gate
support.

The sprint plan also names the dependency order. Finish or park the existing
angle search-path work first, then stabilize parse-error and JSON contracts,
then corpus lanes and hash enforcement, then host/core/proof tracks, and close
with CI and roadmap maintenance.
