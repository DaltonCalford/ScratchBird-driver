# R Driver Specification

Status: Partial
Priority: P2

## Implementation Status

- Current lane verdict: `partial`
- Source of truth: `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- Selected benchmark: `RPostgres`
- Track root: `tracks/p3/drivers/r`

## Competitive Closure Targets

- freeze DBI ergonomics and metadata expectations against RPostgres
- require connection/auth proof and richer metadata-family validation

## Remaining Implementation Deltas

- CONN: connection/auth integration coverage remains environment-gated
- META: richer privilege/key/type and DDL-editor metadata parity remains incomplete

## Required Release Evidence

This lane must stage a complete evidence pack under:

`release/readiness/r/<version>/`

Required files are defined by:

- `docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
- `docs/development/release-evidence/README.md`

## Later Server Verification

The later live verification packet for this lane is:

`docs/development/server-verification/r.md`

## Non-Goals

- foreign wire-protocol emulation
- server-side UDR connector work
- inventing lane behavior that contradicts SBWP v1.1, MGA, or current repo truth
