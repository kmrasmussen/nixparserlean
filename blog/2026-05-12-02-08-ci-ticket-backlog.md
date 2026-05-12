# CI Ticket Backlog

The backlog now includes CI-focused work for this repository.

The project already has a strong local `nix flake check` gate, but the next
operational step is to make that contract explicit in GitHub Actions and in a
local pre-push command. The new tickets cover:

- GitHub Actions running `nix flake check`;
- a local pre-push/check script with the same gate;
- documentation for required, optional, and network-backed checks.

These are ticketed separately so CI infrastructure can land without mixing into
parser, evaluator, or proof work.
