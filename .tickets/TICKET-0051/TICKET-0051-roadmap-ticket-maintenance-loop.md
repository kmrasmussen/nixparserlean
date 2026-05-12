# TICKET-0051: Roadmap Ticket Maintenance Loop

## Problem
The new root roadmap will drift unless the project has a routine for updating
it after completed tickets and corpus changes.

## Goal
Establish a lightweight roadmap maintenance loop.

## In Scope
- Add or update documentation for when to refresh `roadmap/`.
- Add a simple checklist for completed tickets.
- Ensure future tickets can be generated from roadmap milestones.
- Optionally add a small script for listing non-completed tickets.

## Out of Scope
- Replacing `.tickets` with another tracker.
- CI automation.

## Acceptance Criteria
1. Roadmap maintenance expectations are documented.
2. A command or checklist identifies open/non-completed tickets.
3. The process does not add heavy tooling.
