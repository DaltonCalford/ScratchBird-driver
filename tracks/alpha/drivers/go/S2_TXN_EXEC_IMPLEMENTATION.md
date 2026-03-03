# S2 TXN/EXEC Implementation (DLB-GO-003)

Scope: `tracks/alpha/drivers/go` lane only.

## Changes
- `BeginTx` now rejects unsupported isolation levels with structured `ErrNotSupported` (`SQLSTATE 0A000`) instead of silently falling back to read committed.
- `ExecContext` now forces execution `maxRows=0` for both simple and extended paths so execution semantics are not altered by configured `FetchSize`.
- Added internal helpers to separate execution/query paging behavior:
  - `sendSimpleQueryWithMaxRows(...)`
  - `sendExtendedQueryWithMaxRows(...)`
- Added focused wire-level tests for TXN and EXEC behavior in `txn_exec_test.go`.

## Tests Run
- `cd tracks/alpha/drivers/go && go test . -run 'TestBeginTxRejectsUnsupportedIsolation|TestBeginTxEncodesIsolationAndReadOnly|TestExecContextSimpleIgnoresFetchSizeForExec|TestExecContextExtendedIgnoresFetchSizeForExec'`
  - Result: `PASS` (`ok github.com/scratchbird/scratchbird-go 0.003s`)

## TXN Status
- Recommendation: `PARTIAL`
- Covered in lane:
  - Begin/BeginTx transaction start path with wire payloads.
  - Commit/Rollback wire commands.
  - Unsupported isolation handling now explicit and tested.
- Remaining gaps:
  - Savepoint API is still not surfaced on `Conn`/`Tx` (payload builders exist only).

## EXEC Status
- Recommendation: `PARTIAL`
- Covered in lane:
  - Simple and extended execution paths.
  - Exec result handling (`RowsAffected`, `LastInsertId` behavior).
  - Exec fetch-size safety fix (`maxRows=0`) with targeted tests.
- Remaining gaps:
  - `Rows.NextResultSet` is not implemented, so multi-result-set behavior remains unproven.
