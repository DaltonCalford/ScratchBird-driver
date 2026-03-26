# ScratchBird Driver MGA Reconnect And Transaction Recovery Audit

This note defines how ScratchBird drivers participate in recovery when the engine itself is MGA/state based.

## Driver Rule

Drivers do not perform WAL-style transaction replay.

They are responsible for:

- reconnecting transport/session state when the connection is lost
- resetting local client state after disconnect or cancel
- issuing explicit rollback/reset/retry when the protocol and API contract allow it
- resuming result delivery only for explicit suspended/portal-resume protocol states

They must not assume that reconnect resurrects an in-flight transaction or replays lost statements.

## Why

ScratchBird engine truth lives in MGA state, not a redo log. After disconnect or crash:

- committed truth is recovered by the engine from TIP/CLOG, page state, and checkpoint markers
- uncommitted work is finalized by engine recovery rules
- client libraries may reopen sessions and retry operations, but they do not reconstruct transaction history

## Canonical Transaction Semantics

The driver layer must describe the engine in its real MGA terms, not as a flat
begin/commit wrapper. The canonical isolation modes are:

- `READ COMMITTED`
- `READ COMMITTED READ CONSISTENCY`
- `SNAPSHOT`
- `SNAPSHOT TABLE STABILITY`

Lane documentation and code must make clear:

- which public API selects which canonical mode
- whether the lane exposes wait/no-wait, timeout, access-mode, deferrable, and
  conflict-policy controls directly
- whether a lane is using a SQL-standard alias such as `SNAPSHOT`,
  `REPEATABLE READ`, or `SERIALIZABLE` for a canonical ScratchBird mode
- which lanes expose a first-class `READ COMMITTED` sub-mode selector and which
  still treat that as an explicit limitation

Mirrored driver-side engine headers, especially under
`tracks/p3/drivers/cli/include/scratchbird/core/`, are informative mirrors of
this contract, not an alternative authority source. They must track the same
MGA, retry-boundary, prepared/limbo, and dormant truth expressed here and in
lane-local code/tests.

## Retry Boundary Rules

Retry policy is boundary-specific:

- SQLSTATE `40001` and `40P01` are statement-restart conditions, not automatic
  whole-transaction replay
- SQLSTATE class `08` is reconnect/reopen only; the abandoned transaction must
  be treated as lost until the engine reports otherwise
- SQLSTATE `57014` is cancel / operator intervention and requires explicit
  caller policy before a new statement attempt

Drivers must surface enough code and tests for auditors to see:

- whether a failure requires statement restart, reconnect, or no automatic
  retry
- that savepoint stacks, cursor state, and local execution caches are discarded
  when the boundary they depend on is lost
- that native `READY` / transaction-status frames own transaction activity;
  `current_txn_id` may legitimately remain `0` on an active engine-endpoint
  session across connect, commit, and rollback, so drivers must not collapse
  "txn id is zero" into "transaction is idle" without checking the
  authoritative activity signal

## Prepared, Limbo, And Dormant States

Prepared 2PC work and dormant detach/reattach are explicit engine-managed
states, not reconnect side effects.

Driver truth must stay explicit here:

- limbo is entered only through an explicit prepare path
- limbo resolution is an explicit commit-prepared or rollback-prepared action
- dormant reattach requires an explicit engine-issued token
- reconnect alone must never be described as a substitute for prepared or
  dormant recovery
- lanes that do not yet expose dormant tokens publicly must fail closed as
  not-supported rather than quietly implying reconnect-based recovery
- explicit suspended-state result resume must also fail closed when the server
  did not report `PORTAL_SUSPENDED`

## Audit Entry Points By Lane

Baseline-mapped lanes:

- `tracks/p3/drivers/cli/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/cpp/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/dart/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/dotnet/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/go/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/jdbc/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/mojo/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/node/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/odbc/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/pascal/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/php/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/python/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/r/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/ruby/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/rust/BASELINE_REQUIREMENT_MAPPING.md`
- `tracks/p3/drivers/swift/BASELINE_REQUIREMENT_MAPPING.md`

Specialty lane with direct README/test anchors:

- `tracks/p3/drivers/elixir/README.md`

## Representative Runtime Anchors

The following files show the live reconnect/recovery behavior that the lane mappings point at:

- JDBC transport and failover reconnect: `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnection.java`
- JDBC pool recovery: `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnectionPool.java`
- JDBC read-committed sub-mode selector: `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnection.java`, `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBProtocolHandler.java`
- JDBC prepared/portal-resume/dormant recovery truth plus native `READY` / `TXN_STATUS` / `current_txn_id` activity handling and focused live recovery proof: `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBConnection.java`, `tracks/p3/drivers/jdbc/src/main/java/com/scratchbird/jdbc/SBProtocolHandler.java`, `tracks/p3/drivers/jdbc/src/test/java/com/scratchbird/jdbc/SBConnectionTransactionModeTest.java`, `tracks/p3/drivers/jdbc/src/test/java/com/scratchbird/jdbc/SBProtocolHandlerSqlStateMappingTest.java`, `tracks/p3/drivers/jdbc/src/test/java/com/scratchbird/jdbc/SBJdbcClosureParityTest.java`
- .NET reconnect / keepalive recovery: `tracks/p3/drivers/dotnet/src/ScratchBird.Data/ScratchBirdConnection.cs`
- .NET transport reset semantics and fresh-boundary adoption truth: `tracks/p3/drivers/dotnet/src/ScratchBird.Data/ProtocolClient.cs`
- .NET read-committed sub-mode selector: `tracks/p3/drivers/dotnet/src/ScratchBird.Data/TransactionOptions.cs`
- .NET prepared/portal-resume/dormant recovery truth: `tracks/p3/drivers/dotnet/src/ScratchBird.Data/ScratchBirdConnection.cs`, `tracks/p3/drivers/dotnet/src/ScratchBird.Data/ProtocolClient.cs`, `tracks/p3/drivers/dotnet/tests/ScratchBird.Data.Tests/TransactionExecutionParityTests.cs`
- Elixir read-committed sub-mode selector: `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`, `tracks/p3/drivers/elixir/lib/scratchbird/protocol.ex`, `tracks/p3/drivers/elixir/lib/scratchbird.ex`
- Elixir prepared/dormant recovery truth and explicit no-portal-resume surface: `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`, `tracks/p3/drivers/elixir/lib/scratchbird.ex`, `tracks/p3/drivers/elixir/test/txn_begin_test.exs`
- C/C++ retry and pool reconnect: `tracks/p3/drivers/cpp/src/pool.cpp`
- C/C++ read-committed sub-mode selector: `tracks/p3/drivers/cpp/include/scratchbird/client/scratchbird_client.h`
- C/C++ prepared/dormant/no-standalone-portal-resume recovery truth: `tracks/p3/drivers/cpp/include/scratchbird/client/scratchbird_client.h`, `tracks/p3/drivers/cpp/include/scratchbird/client/connection.h`, `tracks/p3/drivers/cpp/src/scratchbird_client_c.cpp`, `tracks/p3/drivers/cpp/src/connection.cpp`, `tracks/p3/drivers/cpp/tests/test_driver_connectivity.cpp`
- C/C++ env-gated live reconnect proof: `tracks/p3/drivers/cpp/tests/test_driver_connectivity.cpp` (`DriverRecoveryIntegrationTest.CppReconnectDoesNotResurrectAbandonedTransaction`, `DriverRecoveryIntegrationTest.CApiReconnectDoesNotReuseAbandonedTransactionState`)
- CLI prepared/dormant/no-standalone-portal-resume recovery truth: `tracks/p3/drivers/cli/txn_exec_parity.h`, `tracks/p3/drivers/cli/txn_exec_parity.cpp`, `tracks/p3/drivers/cli/txn_exec_parity_test.cpp`
- ODBC retry helpers: `tracks/p3/drivers/odbc/src/statement_cache.cpp`
- ODBC prepared/dormant/no-standalone-portal-resume recovery truth: `tracks/p3/drivers/odbc/include/scratchbird/odbc/odbc_handles.h`, `tracks/p3/drivers/odbc/src/odbc_handles.cpp`, `tracks/p3/drivers/odbc/tests/test_odbc_catalog_and_types.cpp`
- PHP read-committed sub-mode selector: `tracks/p3/drivers/php/src/Connection.php`, `tracks/p3/drivers/php/src/Protocol.php`
- Python retry / circuit-breaker / pool recovery: `tracks/p3/drivers/python/src/scratchbird/pool.py`, `tracks/p3/drivers/python/src/scratchbird/circuit_breaker.py`, `tracks/p3/drivers/python/src/scratchbird/errors.py`
- Python read-committed sub-mode selector: `tracks/p3/drivers/python/src/scratchbird/connection.py`
- Python prepared/portal-resume/dormant recovery truth plus native `TXN_STATUS`/reopen-boundary handling: `tracks/p3/drivers/python/src/scratchbird/connection.py`, `tracks/p3/drivers/python/tests/test_txn_exec_parity.py`, `tracks/p3/drivers/python/tests/test_integration.py`
- Go SQLSTATE / retry-boundary helpers: `tracks/p3/drivers/go/errors.go`
- Go read-committed sub-mode selector: `tracks/p3/drivers/go/conn.go`, `tracks/p3/drivers/go/protocol.go`
- Go prepared/dormant recovery truth plus active-with-zero-`txn_id`
  fresh-boundary adoption / reopen handling: `tracks/p3/drivers/go/conn.go`,
  `tracks/p3/drivers/go/txn_exec_test.go`,
  `tracks/p3/drivers/go/integration_test.go`
- Node read-committed sub-mode selector: `tracks/p3/drivers/node/src/client.ts`, `tracks/p3/drivers/node/src/protocol.ts`
- Node prepared/portal-resume/dormant recovery truth plus active-with-zero-`txn_id` native boundary handling: `tracks/p3/drivers/node/src/client.ts`, `tracks/p3/drivers/node/test/unit.test.js`, `tracks/p3/drivers/node/test/integration.test.js`
- Ruby read-committed sub-mode selector: `tracks/p3/drivers/ruby/lib/scratchbird/client.rb`, `tracks/p3/drivers/ruby/lib/scratchbird/protocol.rb`
- Ruby prepared/portal-resume/dormant recovery truth: `tracks/p3/drivers/ruby/lib/scratchbird/client.rb`, `tracks/p3/drivers/ruby/lib/scratchbird/connection.rb`, `tracks/p3/drivers/ruby/test/test_txn_exec_parity.rb`, `tracks/p3/drivers/ruby/test/test_wire_txn_exec.rb`, `tracks/p3/drivers/ruby/test/test_result_stream.rb`
- PHP prepared/portal-resume/dormant recovery truth plus
  active-with-zero-`txn_id` fresh-boundary adoption / reopen handling:
  `tracks/p3/drivers/php/src/Connection.php`,
  `tracks/p3/drivers/php/src/ResultStream.php`,
  `tracks/p3/drivers/php/tests/ConnectionTxnExecTest.php`,
  `tracks/p3/drivers/php/tests/IntegrationTest.php`
- Rust read-committed sub-mode selector: `tracks/p3/drivers/rust/src/client.rs`, `tracks/p3/drivers/rust/src/protocol.rs`
- Rust prepared/portal-resume/dormant recovery truth plus active-with-zero-`txn_id` fresh-boundary adoption: `tracks/p3/drivers/rust/src/client.rs`, `tracks/p3/drivers/rust/tests/integration_test.rs`, `tracks/p3/drivers/rust/tests/runtime_contract_gate_test.rs`, `tracks/p3/drivers/rust/README.md`, `tracks/p3/drivers/rust/BASELINE_REQUIREMENT_MAPPING.md`
- Swift read-committed sub-mode selector: `tracks/p3/drivers/swift/Sources/ScratchBird/Connection.swift`, `tracks/p3/drivers/swift/Sources/ScratchBird/Protocol.swift`
- Swift prepared/portal-resume/dormant recovery truth plus native `READY` / `TXN_STATUS` / reopen-boundary handling: `tracks/p3/drivers/swift/Sources/ScratchBird/Connection.swift`, `tracks/p3/drivers/swift/Sources/ScratchBird/TxnExecValidation.swift`, `tracks/p3/drivers/swift/Tests/ScratchBirdTests/TxnExecParityTests.swift`, `tracks/p3/drivers/swift/Tests/ScratchBirdTests/IntegrationTests.swift`
- Dart read-committed sub-mode selector: `tracks/p3/drivers/dart/lib/src/client.dart`, `tracks/p3/drivers/dart/lib/src/protocol.dart`
- Dart prepared/portal-resume/dormant recovery truth and live native transaction-boundary certification: `tracks/p3/drivers/dart/lib/src/client.dart`, `tracks/p3/drivers/dart/test/txn_exec_parity_test.dart`, `tracks/p3/drivers/dart/test/integration_test.dart`
- R reconnect-required state handling and read-committed sub-mode selector: `tracks/p3/drivers/r/R/client.R`, `tracks/p3/drivers/r/R/protocol.R`
- R prepared/portal-resume/dormant recovery truth plus native `READY` / `TXN_STATUS` / one-stray-reopen-READY handling: `tracks/p3/drivers/r/R/client.R`, `tracks/p3/drivers/r/R/protocol.R`, `tracks/p3/drivers/r/tests/testthat/test_exec_lifecycle.R`, `tracks/p3/drivers/r/tests/testthat/test_txn_exec_parity.R`, `tracks/p3/drivers/r/tests/testthat/test_integration.R`
- Mojo reconnect-required state handling and read-committed sub-mode selector: `tracks/p3/drivers/mojo/src/scratchbird.py`
- Mojo prepared/dormant/no-standalone-portal-resume recovery truth plus native fresh-boundary adoption / post-rollback query proof on the Python-wire bridge: `tracks/p3/drivers/mojo/src/scratchbird.py`, `tracks/p3/drivers/mojo/tests/txn_exec_parity.py`, `tracks/p3/drivers/mojo/tests/wire_transport_bridge.py`, `tracks/p3/drivers/mojo/tests/integration.py`
- Pascal read-committed sub-mode selector: `tracks/p3/drivers/pascal/src/ScratchBird.Client.pas`, `tracks/p3/drivers/pascal/src/ScratchBird.Protocol.pas`
- Pascal prepared/portal-resume/dormant recovery truth: `tracks/p3/drivers/pascal/src/ScratchBird.Client.pas`, `tracks/p3/drivers/pascal/tests/TxnExecParityTests.pas`, `tracks/p3/drivers/pascal/tests/StreamControlBackpressureTests.pas`

## Contract Summary

For auditors, the intended interpretation is:

- engine recovery is MGA and authoritative
- drivers repair client connectivity and session state
- transaction recovery at the driver layer means reset, rollback, reopen, or retry against engine truth
- retriable conditions are classified by boundary (`statement`, `reconnect`, or `none`), not by in-place replay
- prepared / limbo and dormant reattach are explicit engine surfaces, never implicit reconnect behavior
- no driver is expected to implement WAL replay

That separation is required so every driver stays aligned to the same engine model.
