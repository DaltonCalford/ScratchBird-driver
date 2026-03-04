# DLB-RUST-003 S2 TXN/EXEC Implementation

Date: 2026-03-04  
Lane: `tracks/alpha/drivers/rust`

## Changes

- Added callable SQL normalization support in `src/sql.rs`:
  - `normalize_callable(...)`
  - `normalize_callable_sql(...)`
  - JDBC escape call forms:
    - `{ call proc(...) }`
    - `{ ? = call func(...) }`
- Added EXEC parity surfaces to `Client` in `src/client.rs`:
  - `native_callable_sql(sql, params)`
  - `call(sql, params)`
  - `query_multi(sql, params)` / `execute_multi(sql, params)`
  - `execute_batch(sql, batch_params)` / `query_batch(sql, batch_params)`
  - `execute_with_generated_keys(sql, params)`
- Added result summary models in `src/client.rs`:
  - `FieldSummary`
  - `ResultSetSummary`
  - `BatchItemSummary`
  - `BatchSummary`
- Added multi-result parsing pipeline (`collect_result_sets`) that captures:
  - rows
  - row count
  - field metadata
  - command tag
  - generated key (`last_insert_id`) per command-complete boundary.
- Kept existing TXN guardrails and savepoint validation introduced earlier:
  - nested begin rejection
  - commit/rollback/savepoint lifecycle state checks
  - blank savepoint name rejection
  - transaction id synchronization via `apply_txn_state(...)`.

## Tests Run

1. `cargo test`  
   Result: PASS  
   - lib tests: 13 passed  
   - integration tests: 8 passed  
   - metadata tests: 6 passed  
   - sql tests: 8 passed  
   - types tests: 3 passed

## TXN Status

Recommendation: `PARTIAL`

Why:
- Begin/commit/rollback/savepoint/release/rollback-to-savepoint paths are guarded and tested.
- Remaining parity gap: explicit public autocommit control semantics are still not exposed as a first-class TXN API.

## EXEC Status

Recommendation: `IMPLEMENTED`

Why:
- Callable SQL normalization and callable execution are now exposed.
- Multi-result traversal and batch execution APIs are implemented and tested.
- Generated-key extraction API is implemented and tested.
- Unit and integration tests now cover core EXEC parity paths.

## Remaining Gaps

- TXN:
  - Add explicit public autocommit control API with JDBC-parity semantics.
