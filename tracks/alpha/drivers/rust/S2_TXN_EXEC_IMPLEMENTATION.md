# DLB-RUST-003 S2 TXN/EXEC Implementation

Date: 2026-03-03  
Lane: `tracks/alpha/drivers/rust`

## Changes

- Added TXN state guardrails in `Client`:
  - reject nested `begin_transaction` when a transaction is already active;
  - reject `commit_transaction`/`rollback_transaction`/savepoint operations when no transaction is active.
- Added savepoint input validation so blank/whitespace savepoint names are rejected.
- Added `native_sql(sql, params)` for execution-parity SQL normalization without execution.
- Centralized transaction id synchronization via `apply_txn_state(...)` and used it across `READY`/parameter-status handling paths.
- Reset transaction id during `close()` to avoid stale local TXN state.
- Hardened SQL normalization (`src/sql.rs`) so positional/named placeholder rewriting ignores placeholders inside escaped SQL string literals (`''`).
- Added focused TXN/EXEC unit tests:
  - TXN guard and savepoint validation tests in `src/client.rs` test module.
  - EXEC normalization edge tests in `tests/sql_test.rs`.

## Tests Run

1. `cargo test --lib native_sql_rewrites_named_placeholders -- --nocapture`  
   Result: PASS (1 passed, 0 failed)
2. `cargo test --lib transaction_state_guards_enforce_begin_commit_rules -- --nocapture`  
   Result: PASS (1 passed, 0 failed)
3. `cargo test --lib savepoint_name_validation_rejects_blank -- --nocapture`  
   Result: PASS (1 passed, 0 failed)
4. `cargo test --test sql_test -- --nocapture`  
   Result: PASS (5 passed, 0 failed)

## TXN Status

Recommendation: `PARTIAL`

Why:
- Begin/commit/rollback/savepoint/release/rollback-to-savepoint paths now have deterministic local guardrails and lane tests.
- Remaining parity gaps include broader transaction surface expectations (for example, first-class autocommit semantics and deeper live integration coverage of multi-step transaction flows).

## EXEC Status

Recommendation: `PARTIAL`

Why:
- SQL normalization and execution entry paths are in place, and normalization edge behavior for escaped literals is now directly tested.
- Remaining parity gaps include higher-level JDBC-style execution surfaces (for example batch APIs, multi-result traversal, and generated-key/callable-style result semantics).

## Remaining Gaps

- TXN:
  - No explicit public autocommit control API with parity semantics.
  - No lane-local live integration tests for full savepoint lifecycle transitions.
- EXEC:
  - No explicit batch execution API.
  - No multi-result-set traversal API.
  - No dedicated generated-key retrieval/callable execution surface.
