# ScratchBird .NET Driver

ScratchBird ADO.NET provider using the native wire protocol.

## Documentation

- [Getting started](../../../../docs/getting-started/dotnet.md)
- [API reference](../../../../docs/api-reference/dotnet.md)
- [Baseline requirement mapping](BASELINE_REQUIREMENT_MAPPING.md)

## MGA Recovery Contract

This lane follows ScratchBird's MGA/state-based engine recovery model.

- reconnect or reopen only repairs transport and session state
- reconnect never resurrects abandoned in-flight transactions or replay lost statements
- transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth
- result resume is valid only for explicit suspended protocol states
- `PrepareTransaction(...)`, `CommitPrepared(...)`, and
  `RollbackPrepared(...)` now expose explicit prepared / limbo control
  surfaces through canonical transaction-control SQL
- `SupportsDormantReattach() -> false`, `DetachToDormant()`, and
  `ReattachDormant(...)` make dormant truth explicit and fail closed with
  `0A000` until the public front door exposes a real dormant token flow
- `BeginTransaction(ScratchBirdTransactionOptions)` exposes the canonical MGA
  begin flags for `IsolationLevel`, `AccessMode`, `Deferrable`, `Wait`,
  `TimeoutMs`, `AutoCommit`, and `ReadCommittedMode`
- native `READY`, `TXN_STATUS`, and `current_txn_id` are treated as
  authoritative transaction-state surfaces, so a fresh native session
  boundary can remain active with `txn_id == 0`
- parameterless / default `READ COMMITTED` begin on the live native lane now
  adopts that already-active fresh boundary instead of sending a second
  `TXN_BEGIN`; non-default fresh-boundary adoption stays fail-closed with
  `0A000` until an explicit live server path exists
- current isolation alias mapping is explicit in lane source:
  `IsolationLevel.ReadCommitted` => canonical `READ COMMITTED`,
  `IsolationLevel.RepeatableRead` => canonical `SNAPSHOT`,
  `IsolationLevel.Serializable` / `Snapshot` / `Chaos` => canonical
  `SNAPSHOT TABLE STABILITY`
- `ScratchBirdReadCommittedMode` now exposes the canonical `READ COMMITTED`
  sub-modes directly; `ScratchBirdReadCommittedMode.ReadConsistency` selects
  canonical `READ COMMITTED READ CONSISTENCY`
- `ScratchBirdSqlStateMapper.RetryScopeForSqlState(...)` makes the retry
  boundary explicit: `40001`/`40P01` => fresh statement only, `08xxx` =>
  reconnect or reopen only, everything else => no automatic replay
- `ProtocolClient.ResumeSuspendedPortal(...)` now rejects unsuspended resume
  with `55000`, and the query/read paths only call it after
  `PORTAL_SUSPENDED`

See `../../../../docs/audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md`.

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Build

```bash
dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj
```

## Tests

```bash
dotnet test
```

Integration env:

- `SCRATCHBIRD_DOTNET_URL`

## Enterprise soak/fault harnesses

Deterministic mode:

```bash
bash artifacts/enterprise-readiness/run_dotnet_soak_suite.sh

# or per-ticket:
bash artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh
bash artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_failover_soak.sh
bash artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh
```

Runtime mode (requires live DSN):

```bash
DOTNET_HARNESS_MODE=runtime SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
bash artifacts/enterprise-readiness/run_dotnet_soak_suite.sh

# or per-ticket:
DOTNET_HARNESS_MODE=runtime SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
bash artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh

DOTNET_HARNESS_MODE=runtime SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
bash artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_failover_soak.sh

DOTNET_HARNESS_MODE=runtime SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
bash artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh
```
