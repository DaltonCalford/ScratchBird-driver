# .NET Driver Implementation Plan

Status: Current
Priority: P0

## Phase 1 - Offline-Complete Work

- freeze benchmark target `Npgsql`
- push current lane truth into authoritative lane docs
- enumerate remaining implementation deltas with no hidden assumptions
- wire shared release-evidence requirements into this lane
- define later server-verification commands and artifact paths

## Phase 2 - Remaining Code Or Live-Proof Work

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is competitive proof, packaging polish, and later live evidence collection

## Later Build / Verification Commands

Build/bootstrap commands:

- `cd tracks/p3/drivers/dotnet`
- `dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj`

Verification commands:

- `dotnet test`

## Output Contracts

- release evidence under `release/readiness/dotnet/<version>/`
- later verification packet in `docs/development/server-verification/dotnet.md`
