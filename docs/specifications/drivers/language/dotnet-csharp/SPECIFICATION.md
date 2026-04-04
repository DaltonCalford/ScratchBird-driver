# .NET Driver Specification

Status: Complete
Priority: P0

## Implementation Status

- Current lane verdict: `baseline_complete`
- Source of truth: `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- Selected benchmark: `Npgsql`
- Track root: `tracks/p3/drivers/dotnet`

## Competitive Closure Targets

- freeze Npgsql-class diagnostics, pooling expectations, and release evidence requirements
- require reproducible compatibility matrices and benchmark output in the release pack

## Remaining Implementation Deltas

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is competitive proof, packaging polish, and later live evidence collection

## Required Release Evidence

This lane must stage a complete evidence pack under:

`release/readiness/dotnet/<version>/`

Required files are defined by:

- `docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
- `docs/development/release-evidence/README.md`

## Later Server Verification

The later live verification packet for this lane is:

`docs/development/server-verification/dotnet.md`

## Non-Goals

- foreign wire-protocol emulation
- server-side UDR connector work
- inventing lane behavior that contradicts SBWP v1.1, MGA, or current repo truth
