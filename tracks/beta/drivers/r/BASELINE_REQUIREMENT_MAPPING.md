# ScratchBird Driver Baseline Requirement Mapping (S0)

Scope: lane-local S0 artifact only for `tracks/beta/drivers/r`.

## CONN -> JDBCBL-CONN

- Current status: `Partial`
- Lane-local source anchors:
  - `R/config.R:8` (`sb_config` defaults and DSN entrypoint)
  - `R/config.R:69` (`parse_uri_dsn`)
  - `R/config.R:105` (`parse_kv_dsn`)
  - `R/client.R:8` (`sb_connect` connection validation + bootstrap path)
  - `R/client.R:241` (`sb_open_socket` enforces TLS-required transport)
  - `R/client.R:312` (`sb_perform_manager_connect` manager-proxy auth flow)
  - `R/client.R:401` (`sb_startup_and_auth` startup/auth handshake loop)
  - `R/protocol.R:155` (`read_u32` unsigned protocol length decode)
  - `R/protocol.R:222` / `R/protocol.R:229` / `R/protocol.R:239` (auth frame parsers)
  - `R/native_transport.R:9` (`sb_tls_connect_native` native TLS call bridge)
  - `R/dbi.R:16` / `R/dbi.R:23` / `R/dbi.R:35` / `R/dbi.R:40` (`dbConnect`, `dbCanConnect`, `dbDisconnect`, `dbIsValid`)
- Lane-local test anchors:
  - `tests/testthat/test_config.R:8`
  - `tests/testthat/test_config.R:22`
  - `tests/testthat/test_config.R:33`
  - `tests/testthat/test_conn_protocol.R:8`
  - `tests/testthat/test_conn_protocol.R:32`
  - `tests/testthat/test_conn_protocol.R:70`
  - `tests/testthat/test_conn_protocol.R:90`
  - `tests/testthat/test_conn_protocol.R:98`
  - `tests/testthat/test_conn_protocol.R:118`
  - `tests/testthat/test_conn_protocol.R:124`
  - `tests/testthat/test_transport_tls.R:9`
  - `tests/testthat/test_integration.R:8`
- Gaps / next actions:
  - Connection constraints are explicit (`binary_transfer=false` and `compression=zstd` are rejected in `R/client.R:19` and `R/client.R:20`).
  - Integration connection/auth coverage remains environment-gated (`tests/testthat/test_integration.R` still depends on `SCRATCHBIRD_R_URL`).
  - Add live-manager-proxy handshake coverage (currently unit-tested at parser/config boundaries only).

## TXN -> JDBCBL-TXN

- Current status: `Partial`
- Lane-local source anchors:
  - `R/client.R:86` (`sb_begin`)
  - `R/client.R:113` (`sb_commit`)
  - `R/client.R:119` (`sb_rollback`)
  - `R/client.R:125` / `R/client.R:131` / `R/client.R:137` (savepoint operations)
  - `R/client.R:48` (`sb_set_autocommit`, local state toggle)
  - `R/dbi.R:44` / `R/dbi.R:50` / `R/dbi.R:56` (`dbBegin`, `dbCommit`, `dbRollback`)
- Lane-local test anchors:
  - `tests/testthat/test_txn_exec_parity.R:18` (DBI transaction lifecycle + autocommit alignment)
  - `tests/testthat/test_txn_exec_parity.R:75` (wire message coverage for begin/commit/rollback/savepoint/release/rollback-to)
- Gaps / next actions:
  - Add live integration coverage for begin/commit/rollback/savepoint semantics (current evidence is unit/mock based).
  - Validate local autocommit toggles against server-side transaction status across failure paths.
  - Consider DBI-level savepoint helpers if S2 parity scope requires savepoint operations through DBI generic methods.

## EXEC -> JDBCBL-EXEC

- Current status: `Implemented`
- Lane-local source anchors:
  - `R/dbi.R:62` / `R/dbi.R:67` / `R/dbi.R:71` / `R/dbi.R:76` / `R/dbi.R:84` (DBI send/fetch/clear/rows-affected/execute methods)
  - `R/sql.R:8` / `R/sql.R:38` / `R/sql.R:76` (SQL normalization and placeholder rewrites)
  - `R/client.R:56` / `R/client.R:66` (`sb_query`, `sb_send_query`)
  - `R/client.R:493` (`sb_execute_query`)
  - `R/client.R:544` (`sb_fetch_rows`)
  - `R/client.R:642` (extended query parse/bind/execute path)
- Lane-local test anchors:
  - `tests/testthat/test_sql.R:8`
  - `tests/testthat/test_sql.R:15`
  - `tests/testthat/test_sql.R:22`
  - `tests/testthat/test_txn_exec_parity.R:141` (`dbSendQuery` + `dbFetch` + `dbClearResult` lifecycle)
  - `tests/testthat/test_txn_exec_parity.R:182` (`dbExecute` rowcount + full drain behavior)
  - `tests/testthat/test_integration.R:8`
  - `tests/testthat/test_integration.R:19`
- Gaps / next actions:
  - Expand live integration coverage for incremental fetch/result lifecycle (current new lifecycle checks are mock based).
  - Add negative-path execution coverage (server error + resource cleanup) in deterministic unit tests.

## META -> JDBCBL-META

- Current status: `Partial`
- Lane-local source anchors:
  - `R/metadata.R:3` (`sb_metadata_schemas_query`)
  - `R/metadata.R:7` (`sb_metadata_tables_query`)
  - `R/metadata.R:11` (`sb_metadata_columns_query`)
  - `R/metadata.R:18` / `R/metadata.R:22` / `R/metadata.R:26` / `R/metadata.R:30` / `R/metadata.R:34` (indexes/constraints/procedures/functions)
  - `R/metadata.R:45` (`sb_metadata_schema_paths_for_navigation`, dotted parent expansion path shaping)
  - `R/metadata.R:69` (`sb_metadata_build_schema_tree`, recursive tree shaping with per-parent uniqueness)
  - `R/metadata.R:117` (`sb_metadata_build_schema_tree_rows`, database/default branch-style row shaping)
  - `R/dbi.R:90` (`dbListTables`, metadata-only table discovery with schema qualification)
  - `R/dbi.R:120` / `R/dbi.R:131` / `R/dbi.R:142` (`dbExistsTable` for `character`/`Id`/`SQL` names)
  - `R/dbi.R:153` / `R/dbi.R:198` / `R/dbi.R:243` (`dbListFields` for `character`/`Id`/`SQL` names)
  - `R/dbi.R:393` (`sb_metadata_tables_with_schema`, table->schema enrichment from metadata)
  - `R/dbi.R:426` (`sb_filter_tables_for_ref`, schema/table reference matching)
  - `NAMESPACE:18` through `NAMESPACE:28` (metadata helper + recursive schema shaping exports)
- Lane-local test anchors:
  - `tests/testthat/test_metadata_recursive_schema.R:17` (database/default branch-style rows with top-level branches)
  - `tests/testthat/test_metadata_recursive_schema.R:32` (dotted parent expansion for schema navigation paths)
  - `tests/testthat/test_metadata_recursive_schema.R:44` (per-parent uniqueness for duplicate leaf paths)
  - `tests/testthat/test_metadata_recursive_schema.R:58` (same leaf name preserved under different parents)
  - `tests/testthat/test_metadata_execution.R:14` (`dbListTables` metadata-only listing behavior)
  - `tests/testthat/test_metadata_execution.R:41` (`dbExistsTable` metadata-only lookup behavior)
  - `tests/testthat/test_metadata_execution.R:69` (`dbListFields` metadata-only column listing behavior)
- Gaps / next actions:
  - Add live metadata integration coverage to validate engine-backed metadata payload completeness beyond recursive schema tree shaping and mocked DBI metadata method tests.
  - Expand metadata-family coverage toward richer privilege/key/type and DDL-editor payload parity expectations.

## TYPE -> JDBCBL-TYPE

- Current status: `Partial`
- Lane-local source anchors:
  - `R/types.R:88` (`encode_param`)
  - `R/types.R:174` (`decode_value`)
  - `R/types.R:184` (`decode_binary_value`)
  - `R/types.R:342` / `R/types.R:393` (range encode/decode)
  - `R/types.R:448` / `R/types.R:475` (composite encode/decode)
  - `R/client.R:556` (row decode calls `decode_value`)
- Lane-local test anchors:
  - `tests/testthat/test_types.R:8`
  - `tests/testthat/test_types.R:14`
  - `tests/testthat/test_integration.R:31`
- Gaps / next actions:
  - Add focused tests for JSON/JSONB, temporal types, range/composite, geometry, and array encoding/decoding paths in `R/types.R`.
  - Add assertions for round-trip behavior through query execution paths, not just unit-level decoders.

## ERR -> JDBCBL-ERR

- Current status: `Implemented`
- Lane-local source anchors:
  - `R/protocol.R:590` (`parse_error_message`)
  - `R/client.R:565` (`sb_sqlstate_error_class`)
  - `R/client.R:615` (`sb_raise_query_error`)
  - `R/client.R:518` / `R/client.R:680` (error handling in query/drain loops and describe flow)
  - `R/client.R:711` (parameter-count mismatch guard)
- Lane-local test anchors:
  - `tests/testthat/test_error_parity.R:25` (exact + class-prefix SQLSTATE mapping coverage)
  - `tests/testthat/test_error_parity.R:34` (typed condition class + SQLSTATE/detail/hint propagation)
  - `tests/testthat/test_error_parity.R:59` (unknown SQLSTATE class fallback)
  - `tests/testthat/test_error_parity.R:74` (empty-SQLSTATE generic fallback)
  - `tests/testthat/test_integration.R:42` (cancel path expects error)
  - `tests/testthat/test_config.R:40` (config validation error path)

## RES -> JDBCBL-RES

- Current status: `Partial`
- Lane-local source anchors:
  - `R/dbi.R:23` (`dbDisconnect`)
  - `R/dbi.R:41` (`dbClearResult`)
  - `R/client.R:43` (`sb_disconnect`)
  - `R/client.R:76` (`sb_clear_result`)
  - `R/client.R:81` (`sb_cancel`)
  - `R/client.R:164` (`sb_terminate`)
  - `R/client.R:258` (`sb_socket_close`)
  - `src/tls_transport.c:78` / `src/tls_transport.c:490` (native transport finalizer and explicit close)
- Lane-local test anchors:
  - `tests/testthat/test_integration.R:14`
  - `tests/testthat/test_integration.R:25`
  - `tests/testthat/test_integration.R:37`
  - `tests/testthat/test_integration.R:52`
  - `tests/testthat/test_integration.R:42`
- Gaps / next actions:
  - Add explicit tests for `dbClearResult`, repeated disconnect/close behavior, and cleanup after errors.
  - Add resource lifecycle checks for long-running fetch/cancel scenarios.
