# ScratchBird PDO Driver (Userland)

Pure-PHP ScratchBird PDO-style driver using the native wire protocol.

## Documentation

- [Getting started](../../../../docs/getting-started/php.md)
- [API reference](../../../../docs/api-reference/php.md)
- Baseline requirement mapping: [BASELINE_REQUIREMENT_MAPPING.md](BASELINE_REQUIREMENT_MAPPING.md)

## MGA Recovery Contract

This lane follows ScratchBird's MGA/state-based engine recovery model.

- reconnect or reopen only repairs transport and session state
- reconnect never resurrects abandoned in-flight transactions or replay lost statements
- transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth
- result resume is valid only for explicit suspended protocol states
- `Connection::resumePortal()` now fails closed with `55000` unless the server
  first reported `MSG_PORTAL_SUSPENDED`
- `Connection::prepareTransaction()`, `::commitPrepared()`, and
  `::rollbackPrepared()` expose explicit prepared/limbo control through
  canonical transaction-control SQL
- `Connection::supportsDormantReattach()` is explicit and false, and
  `Connection::detachToDormant()` / `::reattachDormant()` fail closed with
  `0A000` until a public dormant front-door exists
- native `READY`, `TXN_STATUS`, and `current_txn_id` are authoritative
  transaction-state surfaces; a fresh engine-endpoint MGA boundary may remain
  active while still reporting `txn_id == 0`
- `Connection::beginTransactionEx(array $options)` exposes the canonical
  `READ COMMITTED` sub-mode selector directly through
  `read_committed_mode`, including `READ COMMITTED READ CONSISTENCY`
- compatible default `beginTransaction()` / `beginTransactionEx(...)` calls
  now adopt that already-active fresh native boundary instead of sending a
  second `TXN_BEGIN`, while unsupported non-default fresh-boundary begin
  requests fail closed with `0A000`
- commit and rollback now drain the immediate reopen boundary before the next
  operation so the follow-on statement sees real result frames rather than a
  stray reopen `READY`
- `Protocol::canonicalReadCommittedModeLabel(...)` makes the selected
  canonical MGA mode visible in lane source and tests
- `ErrorMapper::retryScopeForSqlState(...)` makes the retry boundary explicit:
  `40001`/`40P01` => fresh statement only, `08xxx` => reconnect or reopen
  only, everything else => no automatic replay

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

```php
use ScratchBird\PDO\ScratchBirdPDO;

$pdo = new ScratchBirdPDO("scratchbird://user:pass@localhost:3092/mydb");
$stmt = $pdo->query("SELECT 1");
$row = $stmt->fetch();
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
