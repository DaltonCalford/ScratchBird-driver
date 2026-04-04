# C/C++ Driver Specification

Status: Complete
Priority: P0

## Implementation Status

- Current lane verdict: `baseline_complete`
- Source of truth: `docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md`
- Selected benchmark: `libpqxx`
- Track root: `tracks/p3/drivers/cpp`

## Competitive Closure Targets

- publish allocator, throughput, and streaming evidence against libpqxx-class workloads
- freeze advanced prepared-reuse, TLS diagnostics, and large-result examples as release requirements

## Remaining Implementation Deltas

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is server-backed proof collection and competitive release evidence

## Required Release Evidence

This lane must stage a complete evidence pack under:

`release/readiness/cpp/<version>/`

Required files are defined by:

- `docs/specifications/DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
- `docs/development/release-evidence/README.md`

## Later Server Verification

The later live verification packet for this lane is:

`docs/development/server-verification/cpp.md`

## Non-Goals

- foreign wire-protocol emulation
- server-side UDR connector work
- inventing lane behavior that contradicts SBWP v1.1, MGA, or current repo truth
