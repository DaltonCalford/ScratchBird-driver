# S2 TXN/EXEC Implementation (DLB-GO-003)

Scope: `tracks/alpha/drivers/go` lane only.

## Changes
- `BeginTx` now rejects unsupported isolation levels with structured `ErrNotSupported` (`SQLSTATE 0A000`) instead of silently falling back to read committed.
- `ExecContext` now forces execution `maxRows=0` for both simple and extended paths so execution semantics are not altered by configured `FetchSize`.
- Added internal helpers to separate execution/query paging behavior:
  - `sendSimpleQueryWithMaxRows(...)`
  - `sendExtendedQueryWithMaxRows(...)`
- Added focused wire-level tests for TXN and EXEC behavior in `txn_exec_test.go`.
- Added first-class savepoint APIs on Go connection/transaction types:
  - `Conn.Savepoint(ctx, name)`
  - `Conn.ReleaseSavepoint(ctx, name)`
  - `Conn.RollbackToSavepoint(ctx, name)`
  - `Tx.Savepoint(name)`
  - `Tx.ReleaseSavepoint(name)`
  - `Tx.RollbackToSavepoint(name)`
- Added savepoint validation and state guards:
  - Rejects blank savepoint names with `ErrSyntax` (`SQLSTATE 42601`).
  - Rejects savepoint operations without an active transaction with `ErrTransaction` (`SQLSTATE 25000`).
- Added wire-level savepoint lifecycle tests in `txn_exec_test.go` (begin, savepoint, rollback-to, release, commit).
- Added multi-result traversal support on `Rows`:
  - `Rows.HasNextResultSet()` and `Rows.NextResultSet()` now expose result-set boundaries.
  - Result boundaries are tracked at `COMMAND_COMPLETE` and surfaced before the next set is consumed.
  - `Rows.Close()` now drains across result-set boundaries to final `READY`.
- Added focused wire-level multi-result tests in `rows_next_result_test.go`.
- Added first-class execution translation/summarization APIs in `exec_surfaces.go`:
  - `Conn.NativeSQL(...)` and `Conn.NativeCallableSQL(...)` expose normalized SQL (including JDBC callable escape normalization).
  - `Conn.CallContext(...)` executes callable escape forms through query flow.
  - `Conn.QueryMultiContext(...)` / `Conn.ExecuteMultiContext(...)` return per-result-set summaries (`rows`, `rowCount`, `fields`, `command`, `lastInsertId`).
  - `Conn.ExecuteBatchContext(...)` / `Conn.QueryBatchContext(...)` return per-item batch summaries plus total row count.
  - `Conn.ExecuteWithGeneratedKeysContext(...)` accumulates generated keys across command-complete boundaries.
- Extended lane tests:
  - Added callable normalization tests in `query_test.go`.
  - Added focused wire-level execution-surface tests in `exec_surfaces_test.go` for callable dispatch, multi-result summaries, batch summaries, generated-key accumulation, and normalization APIs.

## Tests Run
- `cd tracks/alpha/drivers/go && go test ./...`
  - Result: `PASS`

## TXN Status
- Recommendation: `PARTIAL`
- Covered in lane:
  - Begin/BeginTx transaction start path with wire payloads.
  - Commit/Rollback wire commands.
  - Unsupported isolation handling now explicit and tested.
  - Savepoint/release/rollback-to API surface with wire validation and error guards.
- Remaining gaps:
  - Broader live transaction integration depth beyond lane unit/wire tests.

## EXEC Status
- Recommendation: `PARTIAL`
- Covered in lane:
  - Simple and extended execution paths.
  - Exec result handling (`RowsAffected`, `LastInsertId` behavior).
  - Exec fetch-size safety fix (`maxRows=0`) with targeted tests.
  - Multi-result traversal via `Rows.HasNextResultSet` / `Rows.NextResultSet` with wire-level tests.
  - Callable normalization/dispatch parity (`NativeCallableSQL`, `CallContext`) with lane tests.
  - First-class batch and multi-result summary APIs (`ExecuteBatchContext`, `QueryBatchContext`, `QueryMultiContext`, `ExecuteMultiContext`) with lane tests.
  - Generated-key accumulation API (`ExecuteWithGeneratedKeysContext`) with lane tests.
- Remaining gaps:
  - Broader live advanced-execution integration depth beyond lane wire/unit tests.
