#!/usr/bin/env bash
set -euo pipefail

found=0

for state in .tickets/TICKET-*/ticket-state.json; do
  ticket_dir=${state%/ticket-state.json}
  ticket=${ticket_dir##*/}
  status=$(
    sed -n 's/.*"status"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$state" |
      head -n 1
  )
  if [ "${status:-unknown}" != "completed" ]; then
    printf '%s\t%s\n' "$ticket" "${status:-unknown}"
    found=1
  fi
done

if [ "$found" -eq 0 ]; then
  printf 'all tickets completed\n'
fi
