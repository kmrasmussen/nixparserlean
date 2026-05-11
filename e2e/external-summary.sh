#!/usr/bin/env sh
set -eu

manifest="${1:-e2e/external-manifest.txt}"

awk -F '\t' '
  /^[[:space:]]*($|#)/ { next }
  $1 == "url" {
    total++
    expectation = $4
    note = $5
  }
  $1 == "file" {
    total++
    expectation = $3
    note = $4
  }
  $1 != "url" && $1 != "file" {
    total++
    expectation = $2
    note = $3
  }
  expectation == "pass" {
    pass++
    next
  }
  {
    nonpass++
    blocker = note
    sub(/^blocker: /, "", blocker)
    sub(/;.*/, "", blocker)
    if (blocker == "") {
      blocker = expectation
    }
    blockers[blocker]++
  }
  END {
    printf "external cases: %d\n", total
    printf "passes: %d\n", pass
    printf "expected non-pass: %d\n", nonpass
    if (nonpass == 0) {
      print "external blockers: none"
    } else {
      for (blocker in blockers) {
        printf "%d\t%s\n", blockers[blocker], blocker
      }
    }
  }
' "$manifest"

