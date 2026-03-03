# DLB-NODE-003 S2 TXN/EXEC Implementation

## Changes
- Added deterministic transaction-state guards in `Client`:
  - `beginTransaction` now rejects nested begin when a transaction is already active.
  - `commitTransaction`, `rollbackTransaction`, `savepoint`, `releaseSavepoint`, and `rollbackToSavepoint` now reject calls when no active transaction exists.
  - Savepoint operations now reject empty/blank savepoint names.
- Added transaction-state synchronization helper (`applyTxnState`) and wired it into READY/current transaction status handling so local guards follow wire-reported transaction id transitions.
- Added `nativeSQL(text, params?)` to provide an explicit native SQL normalization entry point for execution parity.
- Added explicit transaction/session parity API surface:
  - `getAutoCommit()` / `setAutoCommit(enabled)` with deterministic transition behavior.
  - `getSessionSchema()` / `setSessionSchema(schema)` with immediate session apply on connected clients.
  - Implicit transaction begin when `autoCommit=false` and execution starts without an active transaction.
- Added expanded execution API coverage:
  - `queryMulti` and `executeMulti` return distinct result sets.
  - `queryBatch` and `executeBatch` return per-item command summaries.
  - `call` exposes JDBC callable-style invocation normalization and execution.
- Added targeted Node lane unit tests for:
  - Transaction lifecycle and invalid-operation guards.
  - Autocommit transitions and implicit transaction behavior.
  - Session schema setter/getter and emitted schema statement.
  - Savepoint guard behavior and wire call sequence.
  - Extended query wire sequence and named-parameter rewrite.
  - Prepared execute wire sequence and `nativeSQL` normalization.
  - Multi-result and generated-key (`lastId`) result propagation.
  - Callable execution SQL rewrite/delegation.

## Tests Run
- `npm run build && node --test test/unit.test.js` -> PASS
  - 11 tests passed, 0 failed.

## TXN Status
- Recommendation: `PARTIAL`
- Why:
  - Implemented and tested: explicit begin/commit/rollback, savepoint create/release/rollback-to, deterministic invalid-operation guards, and first-class autocommit/session-schema controls.
  - Remaining parity gaps: deeper live transaction parity (beyond lane unit coverage).

## EXEC Status
- Recommendation: `PARTIAL`
- Why:
  - Implemented and tested: simple and prepared execution, positional/named bind normalization, streaming, cancellation, `nativeSQL`, batch execution summaries, multi-result traversal, generated-key propagation, and callable/routine API.
  - Remaining parity gaps: broader live integration depth and additional advanced execution stress cases.

## Remaining Gaps
- TXN
  - Expand live integration validation depth for autocommit and session schema semantics.
- EXEC
  - Add broader multi-statement/live-runtime assertions for mixed result shapes and cancellation races.
