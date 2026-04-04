# .NET Server Verification Packet

Status: server_blocked

## Scope

- lane: `dotnet`
- benchmark: `Npgsql`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/dotnet`

## Required Environment

- `SCRATCHBIRD_DOTNET_URL`
- `SCRATCHBIRD_DOTNET_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/dotnet`
2. `dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj`

## Verification Commands

1. `dotnet test`

## Expected Artifacts

- `release/readiness/dotnet/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/dotnet/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/dotnet/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/dotnet/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/dotnet/<version>/KNOWN_GAPS.md`
- `release/readiness/dotnet/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/dotnet/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/dotnet/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
