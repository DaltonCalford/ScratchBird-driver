# DLB-RUBY-003 S2 TXN/EXEC Implementation

Date: 2026-03-03  
Lane: `tracks/alpha/drivers/ruby`  
Scope: transaction and execution parity improvements with targeted lane-local tests.

## Changes Implemented

1. Shared transaction gate for direct and prepared execution
   - Files:
     - `lib/scratchbird/connection.rb`
     - `lib/scratchbird/statement.rb`
   - Changes:
     - Added `Connection#in_transaction?` and private `begin_transaction_if_needed`.
     - Updated `Connection#execute`, `#query`, and `#stream` to use shared transaction gating and accept `options`.
     - Added `Connection#execute_prepared` and `#stream_prepared`.
     - Updated `Statement#execute` and `#stream` to delegate through connection-level prepared execution.
   - Effect:
     - `autocommit = false` now applies consistently to both direct SQL and prepared statement execution paths.
     - Redundant `BEGIN` calls are avoided while a transaction is already active.
     - Execution options (for example `max_rows`, `timeout_ms`) can flow through connection and statement APIs.

2. Client transaction state exposure for safe gate checks
   - File: `lib/scratchbird/client.rb`
   - Changes:
     - Added `attr_reader :txn_id`.
     - Added `Client#in_transaction?` (`txn_id != 0`).
   - Effect:
     - Connection layer can make transaction gating decisions based on tracked wire-level transaction state.

3. Targeted TXN/EXEC lane unit tests
   - File: `test/test_txn_exec_parity.rb`
   - Added coverage:
     - autocommit-disabled execution starts a transaction once and reuses it
     - commit/rollback reset transaction gate behavior
     - option forwarding for `query` and `stream`
     - prepared statement execute/stream parity through connection transaction gating
     - statement closed-state guard

## Targeted Tests Run

1. `ruby -Itest test/test_txn_exec_parity.rb`
   - Result: PASS
   - Output summary: `5 runs, 20 assertions, 0 failures, 0 errors, 0 skips`

2. `ruby -Itest test/test_sql.rb`
   - Result: PASS
   - Output summary: `3 runs, 6 assertions, 0 failures, 0 errors, 0 skips`

3. `ruby -Itest test/test_conn_auth_protocol.rb`
   - Result: PASS
   - Output summary: `10 runs, 25 assertions, 0 failures, 0 errors, 0 skips`

## Status Recommendation

- TXN: `PARTIAL`
- EXEC: `PARTIAL`

Rationale:
- Core autocommit and prepared execution parity is improved and covered by deterministic lane tests.
- Remaining protocol-level and integration-level coverage gaps still block `MET`.

## Remaining Gaps

1. TXN:
   - Savepoint/release/rollback-to-savepoint paths are present in client code but not yet lane-tested.
   - No live-wire assertions of `READY` transaction state transitions under real server behavior.
   - No deterministic coverage for commit/rollback error handling after server-side transaction aborts.

2. EXEC:
   - No deterministic portal suspend/resume coverage (`max_rows` multi-frame behavior).
   - Streaming lifecycle coverage is still limited (for example `each_hash`, async frame interleaving).
   - Statement close/deallocation protocol behavior is not yet implemented/tested.
