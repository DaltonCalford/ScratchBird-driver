# Go Driver Specification

Status: Complete
Priority: P0

## Implementation Status

- Current lane verdict: `baseline_complete`
- Source of truth: `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- Selected benchmark: `pgx`
- Track root: `tracks/p3/drivers/go`

## Competitive Closure Targets

- freeze pgx-class pool diagnostics, advanced examples, and benchmark evidence

## Remaining Implementation Deltas

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is server-backed benchmark, compatibility, and release proof collection

## Required Release Evidence

This lane must stage a complete evidence pack under:

`release/readiness/go/<version>/`

Required files are defined by:

- `docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
- `docs/development/release-evidence/README.md`

## Later Server Verification

The later live verification packet for this lane is:

`docs/development/server-verification/go.md`

## Non-Goals

- foreign wire-protocol emulation
- server-side UDR connector work
- inventing lane behavior that contradicts SBWP v1.1, MGA, or current repo truth
