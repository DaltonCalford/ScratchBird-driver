# Pascal / Delphi Driver Implementation Plan

Status: Current
Priority: P1

## Phase 1 - Offline-Complete Work

- freeze benchmark target `FireDAC`
- push current lane truth into authoritative lane docs
- enumerate remaining implementation deltas with no hidden assumptions
- wire shared release-evidence requirements into this lane
- define later server-verification commands and artifact paths

## Phase 2 - Remaining Code Or Live-Proof Work

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is live packaging, benchmark, and toolchain validation

## Later Build / Verification Commands

Build/bootstrap commands:

- `fpc -Mdelphi -Fu./tracks/p3/drivers/pascal/src -FE./tracks/p3/drivers/pascal/tests ./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests.pas`

Verification commands:

- `./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests`

## Output Contracts

- release evidence under `release/readiness/pascal/<version>/`
- later verification packet in `docs/development/server-verification/pascal.md`
