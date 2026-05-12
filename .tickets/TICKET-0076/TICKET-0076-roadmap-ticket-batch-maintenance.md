# TICKET-0076: Roadmap Ticket Batch Maintenance

## Problem
The backlog is now intentionally larger. The roadmap needs a routine for
keeping candidate lists, open tickets, and completed ticket summaries aligned
after batches of work.

## Goal
Add a lightweight batch maintenance pass that summarizes open tickets by
roadmap area and keeps `roadmap/07-next-ticket-candidates.md` useful after
promotions.

## In Scope
- Add or update a script/checklist that groups open tickets by roadmap area.
- Update operations docs with when to run the batch maintenance pass.
- Keep the tooling small and shell-friendly.
- Add a blog note if the process changes.

## Out of Scope
- Replacing `.tickets`.
- CI automation.
- A database or web UI.

## Acceptance Criteria
1. There is a command or documented checklist for batch backlog review.
2. Open tickets can be grouped by broad roadmap area.
3. `roadmap/07-next-ticket-candidates.md` remains clearly a staging file, not
   the source of truth after ticket promotion.
4. The process remains lightweight.
