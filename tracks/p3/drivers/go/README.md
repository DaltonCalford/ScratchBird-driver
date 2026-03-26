# ScratchBird Go Driver

ScratchBird native wire protocol driver for Go (`database/sql`).

## Documentation

- [Getting started](../../../../docs/getting-started/go.md)
- [API reference](../../../../docs/api-reference/go.md)
- [Baseline requirement mapping (S0)](BASELINE_REQUIREMENT_MAPPING.md)

## MGA Recovery Contract

This lane follows ScratchBird's MGA/state-based engine recovery model.

- reconnect or reopen only repairs transport and session state
- reconnect never resurrects abandoned in-flight transactions or replay lost statements
- transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth
- result resume is valid only for explicit suspended protocol states
- `PrepareTransaction(...)`, `CommitPrepared(...)`, and
  `RollbackPrepared(...)` now expose explicit prepared / limbo control
  surfaces through canonical transaction-control SQL
- `SupportsDormantReattach() -> false`, `DetachToDormant(...)`, and
  `ReattachDormant(...)` make dormant truth explicit and fail closed with
  `0A000` until the public front door exposes a real dormant token flow
- `database/sql` pool handoff now uses `ResetSession` to roll back abandoned
  explicit transaction state and clear stale plan/SBLR borrower caches before
  reuse
- native `READY`, `TXN_STATUS`, and `current_txn_id` are authoritative
  transaction-state surfaces; a fresh engine-endpoint MGA boundary may remain
  active while still reporting `txn_id == 0`
- `BeginTx(...)` still exposes only the standard `database/sql`
  isolation/read-only subset, but the driver-owned `BeginTxEx(...)` surface
  now exposes the canonical `READ COMMITTED` sub-mode selector directly
- compatible default `READ COMMITTED` `BeginTx(...)` / `BeginTxEx(...)` calls
  now adopt that already-active fresh native boundary instead of sending a
  second `TXN_BEGIN`, while unsupported non-default fresh-boundary begin
  requests fail closed with `0A000`
- commit and rollback now drain the immediate reopen boundary before the next
  operation so the follow-on statement sees real result frames rather than a
  stray reopen `READY`
- `CanonicalIsolationLabelForDriverIsolation(...)` makes the current alias
  mapping explicit in lane source: `READ UNCOMMITTED` remains a legacy
  compatibility alias, `READ COMMITTED` => canonical `READ COMMITTED`,
  `REPEATABLE READ` => canonical `SNAPSHOT`,
  `SERIALIZABLE` => canonical `SNAPSHOT TABLE STABILITY`
- `CanonicalReadCommittedModeLabel(...)` makes the explicit
  `READ COMMITTED` sub-mode selector visible in lane source, including
  `READ COMMITTED READ CONSISTENCY`
- `RetryScopeForSQLState(...)` makes the retry boundary explicit:
  `40001`/`40P01` => fresh statement only, `08xxx` => reconnect or reopen
  only, everything else => no automatic replay
- the lane does not currently expose a standalone portal-resume API; any future
  resume surface must remain limited to explicit suspended protocol states

See `../../../../docs/audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md`.

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Usage

```go
import (
    "database/sql"
    _ "github.com/scratchbird/scratchbird-go"
)

db, err := sql.Open("scratchbird", "scratchbird://user:pass@localhost:3092/db")
```

## Connection strings

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```

## Conformance testing

Set the following environment variables to run the manifest-driven conformance test:

- `SCRATCHBIRD_GO_URL` - ScratchBird DSN/URL for the Go driver
- `SCRATCHBIRD_CONFORMANCE_MANIFEST` - Path to the manifest JSON (e.g., `docs/fixtures/sbwp_conformance_manifest.json`)
