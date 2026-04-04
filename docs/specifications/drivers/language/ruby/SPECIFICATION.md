# Ruby Driver Specification

Status: Complete
Priority: P1

## Implementation Status

- Current lane verdict: `baseline_complete`
- Source of truth: `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- Selected benchmark: `ruby-pg`
- Track root: `tracks/p3/drivers/ruby`

## Competitive Closure Targets

- freeze ruby-pg-class framework examples and release evidence expectations

## Remaining Implementation Deltas

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is live proof collection and packaging evidence

## Required Release Evidence

This lane must stage a complete evidence pack under:

`release/readiness/ruby/<version>/`

Required files are defined by:

- `docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
- `docs/development/release-evidence/README.md`

## Later Server Verification

The later live verification packet for this lane is:

`docs/development/server-verification/ruby.md`

## Non-Goals

- foreign wire-protocol emulation
- server-side UDR connector work
- inventing lane behavior that contradicts SBWP v1.1, MGA, or current repo truth
