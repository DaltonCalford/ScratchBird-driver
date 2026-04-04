# R Driver Implementation Plan

Status: Current
Priority: P2

## Phase 1 - Offline-Complete Work

- freeze benchmark target `RPostgres`
- push current lane truth into authoritative lane docs
- enumerate remaining implementation deltas with no hidden assumptions
- wire shared release-evidence requirements into this lane
- define later server-verification commands and artifact paths

## Phase 2 - Remaining Code Or Live-Proof Work

- CONN: connection/auth integration coverage remains environment-gated
- META: richer privilege/key/type and DDL-editor metadata parity remains incomplete

## Later Build / Verification Commands

Build/bootstrap commands:

- `cd tracks/p3/drivers/r`
- `R CMD build .`

Verification commands:

- `R CMD check scratchbird_*.tar.gz`

## Output Contracts

- release evidence under `release/readiness/r/<version>/`
- later verification packet in `docs/development/server-verification/r.md`
