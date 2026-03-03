# DLB-NODE-003 S2 TXN/EXEC Implementation

## Changes
- Added deterministic transaction-state guards in `Client`:
  - `beginTransaction` now rejects nested begin when a transaction is already active.
  - `commitTransaction`, `rollbackTransaction`, `savepoint`, `releaseSavepoint`, and `rollbackToSavepoint` now reject calls when no active transaction exists.
  - Savepoint operations now reject empty/blank savepoint names.
- Added transaction-state synchronization helper (`applyTxnState`) and wired it into READY/current transaction status handling so local guards follow wire-reported transaction id transitions.
- Added `nativeSQL(text, params?)` to provide an explicit native SQL normalization entry point for execution parity.
- Added targeted Node lane unit tests for:
  - Transaction lifecycle and invalid-operation guards.
  - Savepoint guard behavior and wire call sequence.
  - Extended query wire sequence and named-parameter rewrite.
  - Prepared execute wire sequence and `nativeSQL` normalization.

## Tests Run
- `npm run build && node --test test/unit.test.js` -> PASS
  - 11 tests passed, 0 failed.

## TXN Status
- Recommendation: `PARTIAL`
- Why:
  - Implemented and tested: explicit begin/commit/rollback, savepoint create/release/rollback-to, and deterministic invalid-operation guards.
  - Remaining parity gaps: autocommit-equivalent public API semantics and explicit session schema mutation/getter parity are not fully surfaced as first-class transaction/session APIs.

## EXEC Status
- Recommendation: `PARTIAL`
- Why:
  - Implemented and tested: simple and prepared execution, positional/named bind normalization, streaming, cancellation path, and `nativeSQL` normalization entry point.
  - Remaining parity gaps: no explicit batch API, no explicit multi-result traversal API, generated-key retrieval is not surfaced on `QueryResult`, and callable/routine parity is not exposed as a dedicated high-level API.

## Remaining Gaps
- TXN
  - Add explicit autocommit-equivalent API surface with deterministic transition behavior.
  - Add first-class session schema mutation/getter APIs (beyond connect-time schema and generic option setting).
- EXEC
  - Add batch execution API for statement and prepared flows.
  - Add multi-result traversal API.
  - Surface generated-key metadata (`lastId`) in public execution results.
  - Add a high-level callable/routine invocation API contract.
