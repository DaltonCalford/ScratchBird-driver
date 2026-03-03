# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope
- Lane-local S0 artifact for `tracks/alpha/drivers/cli` only.
- Maps this lane's current capabilities to JDBCBL groups: `CONN`, `TXN`, `EXEC`, `META`, `TYPE`, `ERR`, `RES`.
- All statements below are anchored to files in this lane.

## CONN (JDBCBL: CONN)
- Current status: Implemented
- Lane-local source anchors:
  - `README.md:7-19` documents supported connection modes and connection-string options.
  - `sb_isql.cpp:3071-3189` normalizes connection mode and builds connection target parameters.
  - `sb_isql.cpp:3191-3365` parses `--connection`, `--mode`, `--ipc-*`, and `--conn-opt`.
  - `sb_admin.cpp:145-251` and `sb_security.cpp:202-316` implement equivalent mode normalization and target construction.
  - `sb_isql.cpp:3541-3552`, `sb_admin.cpp:253-266`, `sb_security.cpp:708-725` perform connect calls.
- Lane-local test anchors:
  - `sbdriver_conformance.cpp:657-677` builds client config from DSN and optional appended params.
  - `sbdriver_conformance.cpp:804-827` executes per-test connect flow.
  - `CMakeLists.txt:25,186-199` builds and links `sbdriver_conformance` in this lane.
- Gaps/next actions:
  - Reduce drift by moving duplicated connection target assembly from `sb_isql.cpp`, `sb_admin.cpp`, and `sb_security.cpp` into shared lane code.
  - Add explicit conformance manifests for each documented transport mode (`embedded`, `local-ipc`, `inet`, `managed`).

## TXN (JDBCBL: TXN)
- Current status: Partial
- Lane-local source anchors:
  - `sb_isql.cpp:1196-1359` handles `COMMIT`, `ROLLBACK`, savepoints, and `SET TRANSACTION`.
  - `sb_isql.cpp:935-949` exposes `SET AUTODDL`; `sb_isql.cpp:175` stores `autoddl` in config.
  - `sb_isql.cpp:2678-2688` applies stop/exit behavior after execution errors.
  - `sbdriver_conformance.cpp:712-748` adapts network client begin/commit/rollback operations for conformance runs.
  - `txn_exec_parity.cpp:128-243` implements `txn_exec` flow (`begin -> sql -> commit/rollback -> verify_sql`) with error-safe rollback.
- Lane-local test anchors:
  - `sbdriver_conformance.cpp:829-833,895-897` normalizes `txn` alias and dispatches `txn_exec`.
  - `txn_exec_parity_test.cpp:173-246` covers commit/rollback verification and rollback-on-error behavior.
  - `CMakeLists.txt:208-215` adds the dedicated `sbdriver_txn_exec_tests` lane test target.
- Gaps/next actions:
  - `txn_exec` currently validates begin/commit/rollback only; savepoint/release/rollback-to coverage is still pending.
  - `AUTODDL` is configurable (`sb_isql.cpp:935-949`) but not consumed by a separate transaction-control path in this lane.

## EXEC (JDBCBL: EXEC)
- Current status: Implemented
- Lane-local source anchors:
  - `sb_isql.cpp:1543-1589` executes SQL via client query call and renders results.
  - `sb_admin.cpp:288-305` and `sb_security.cpp:322-339` execute query and non-query SQL paths.
  - `sb_isql.cpp:2409-2425` supports `\plan` by issuing an `EXPLAIN` query.
  - `txn_exec_parity.cpp:79-126` adds `native_exec` validation over row-count and rows-affected expectations.
  - `sbdriver_conformance.cpp:829-833,892-894` normalizes `exec` alias and dispatches `native_exec`.
- Lane-local test anchors:
  - `txn_exec_parity_test.cpp:132-170` validates `native_exec` success and mismatch handling.
  - `txn_exec_parity_test.cpp:173-225` validates execution parity inside transaction commit/rollback flows.
  - `sbdriver_conformance.cpp:874-1230` continues to cover query, prepare, paging, progress, notify, copy, lob, and cancel paths.
- Gaps/next actions:
  - Add live-connection manifest coverage for `native_exec` and `txn_exec` paths in lane CI.
  - `\sblr` remains a placeholder pending client support (`sb_isql.cpp:2435-2443`).

## META (JDBCBL: META)
- Current status: Partial
- Lane-local source anchors:
  - `sb_isql.cpp:1727-1816` maps `\d`-family commands to metadata SQL.
  - `sb_isql.cpp:3473-3501` implements `--schema-tree` output from `sys.catalog.object_resolver`.
  - `sb_isql.cpp:2737-2959` implements DDL extraction for domains, sequences, tables, views, indexes, triggers, procedures, and functions.
- Lane-local test anchors:
  - No metadata-focused lane tests found in `sbdriver_conformance.cpp:829-1185`.
- Gaps/next actions:
  - DDL extraction includes placeholders/fallbacks for missing definitions (`sb_isql.cpp:2750-2752`, `2814-2816`, `2837`, `2925`, `2948`).
  - Add conformance coverage for metadata queries and schema-tree output.

## TYPE (JDBCBL: TYPE)
- Current status: Partial
- Lane-local source anchors:
  - `sbdriver_conformance.cpp:138-580` decodes array/vector/range/network/macaddr/uuid and other OID-tagged values.
  - `sbdriver_conformance.cpp:585-620` encodes JSON params to text/binary bind payloads.
  - `sbdriver_conformance.cpp:689-709` projects typed row values into JSON output.
- Lane-local test anchors:
  - `sbdriver_conformance.cpp:849-885` exercises parameter binding and SQLSTATE checks for prepared execution.
  - `sbdriver_conformance.cpp:1062-1097` validates LOB payload and checksum behavior.
- Gaps/next actions:
  - Unsupported/unknown OIDs fall back to raw byte-string conversion (`sbdriver_conformance.cpp:580`).
  - Add explicit manifests that assert output shape for each decoded type family.

## ERR (JDBCBL: ERR)
- Current status: Implemented
- Lane-local source anchors:
  - `sb_isql.cpp:1574-1583` surfaces execution errors from `core::ErrorContext`.
  - `sb_isql.cpp:2678-2688` enforces `CONTINUE/STOP/EXIT` error handling actions.
  - `sb_admin.cpp:122-124,288-303` and `sb_security.cpp:175-177,322-337` print operation errors.
  - `sbdriver_conformance.cpp:679-687` standardizes error result payloads.
- Lane-local test anchors:
  - `sbdriver_conformance.cpp:850-881` checks expected SQLSTATE behavior for prepared execution failures.
  - `sbdriver_conformance.cpp:1170-1174` checks SQLSTATE for cancel-flow outcomes.
- Gaps/next actions:
  - CLI tools currently print message-first errors; add SQLSTATE/code to user-facing output for parity with conformance assertions.

## RES (JDBCBL: RES)
- Current status: Partial
- Lane-local source anchors:
  - `sb_isql.cpp:3602-3618` disconnects client and closes output/error file handles.
  - `sb_admin.cpp:268-273,658-659` and `sb_security.cpp:727-732,1086-1089` disconnect and free connection state.
  - `sbdriver_conformance.cpp:885,916,957,1153,1187` closes prepared statements and disconnects clients.
- Lane-local test anchors:
  - `sbdriver_conformance.cpp:887-958` exercises repeated statement prepare/execute/close cycles.
  - `sbdriver_conformance.cpp:1106-1169` runs threaded cancel flow with explicit statement close/join.
- Gaps/next actions:
  - Connection and stream lifetime management is still manual (`new/delete`) in multiple CLI entry points; move to RAII wrappers.
  - Add leak/stability checks that loop connect/execute/disconnect paths under this lane.
