# TICKET-0070: Host Import Cycle Normalization Implementation

## Problem
After the relative import normalization policy is decided, recursion detection
needs an implementation that follows that policy.

## Goal
Implement normalized host import cycle detection for the decided relative path
policy while keeping pure path values unchanged.

## In Scope
- Apply the policy from `TICKET-0055`.
- Normalize only in the host import lane.
- Add recursive alias fixtures.
- Preserve existing successful relative imports.
- Update host import docs.

## Out of Scope
- Symlink-heavy canonicalization beyond the policy.
- Pure `Value.path` normalization.
- Angle search paths.
- Store realization.

## Acceptance Criteria
1. Alias-based recursive imports are detected or classified exactly as policy
   says.
2. Import manifest passes.
3. Pure path-value eval fixtures remain unchanged.
4. Docs describe the normalization boundary.
