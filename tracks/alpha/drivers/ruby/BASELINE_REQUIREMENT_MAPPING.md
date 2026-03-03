# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope

- Lane-local S0 artifact only for `tracks/alpha/drivers/ruby`.
- Baseline reflects currently present lane code/tests only.
- Mapping is grouped by JDBCBL capability groups: `CONN`, `TXN`, `EXEC`, `META`, `TYPE`, `ERR`, `RES`.

## CONN (JDBCBL: `CONN`)

- Current status: `Partial`
- Lane-local source anchors:
  - `lib/scratchbird/config.rb:48` (`Config.parse`, URI and key-value handling)
  - `lib/scratchbird/config.rb:91` (`normalize_native_protocol`, `normalize_front_door_mode`)
  - `lib/scratchbird/connection.rb:19` (`Connection#initialize`, `#close`, `#closed?`)
  - `lib/scratchbird/client.rb:68` (`Client#connect`, protocol/front-door normalization, guardrails, connect/auth failure cleanup)
  - `lib/scratchbird/client.rb:400` (`#connect_tcp`) and `lib/scratchbird/client.rb:407` (`#wrap_tls`)
  - `lib/scratchbird/client.rb:469` (`#perform_manager_connect`)
  - `lib/scratchbird/protocol.rb:185` (`parse_auth_request`) and `lib/scratchbird/protocol.rb:192` (`parse_auth_continue`)
- Lane-local test anchors:
  - `test/test_config.rb:11` (`test_parse_uri`)
  - `test/test_config.rb:27` (`test_parse_key_value`)
  - `test/test_config.rb:40` (`test_parse_manager_proxy_params`)
  - `test/test_config.rb:49` (`test_invalid_front_door_mode_raises`)
  - `test/test_conn_auth_protocol.rb:17` (`test_connect_requires_user_and_database`)
  - `test/test_conn_auth_protocol.rb:27` (`test_connect_rejects_binary_transfer_false`)
  - `test/test_conn_auth_protocol.rb:36` (`test_connect_rejects_zstd_compression`)
  - `test/test_conn_auth_protocol.rb:45` (`test_connect_rejects_non_native_protocol`)
  - `test/test_conn_auth_protocol.rb:54` (`test_connect_rejects_invalid_front_door_mode`)
  - `test/test_conn_auth_protocol.rb:63` (`test_wrap_tls_rejects_sslmode_disable`)
  - `test/test_conn_auth_protocol.rb:72` (`test_connect_closes_socket_when_manager_proxy_auth_token_missing`)
  - `test/test_conn_auth_protocol.rb:88` (`test_manager_proxy_auth_failure_raises_auth_error`)
  - `test/test_conn_auth_protocol.rb:116` (`test_protocol_parse_auth_continue_round_trip`)
  - `test/test_conn_auth_protocol.rb:127` (`test_protocol_parse_auth_continue_rejects_truncated_payload`)
  - `test/test_integration.rb:11` (`test_select`, env-gated)
- Gaps / next actions:
  - Add positive-path manager-proxy connection tests against a live MCP endpoint (current coverage is guardrail/error-path only).
  - Add TLS integration tests for certificate and hostname verification modes (`verify-ca`, `verify-full`) against fixture certs.
  - Add SCRAM success/failure handshake integration assertions beyond protocol-frame parsing and manager-token auth failure paths.

## TXN (JDBCBL: `TXN`)

- Current status: `Partial`
- Lane-local source anchors:
  - `lib/scratchbird/connection.rb:37` (`Connection#begin_transaction`, `#commit`, `#rollback`)
  - `lib/scratchbird/connection.rb:50` (`Connection#savepoint`, `#rollback_to_savepoint`, `#release_savepoint`)
  - `lib/scratchbird/connection.rb:52` (`Connection#in_transaction?`, transaction-state gate delegated to client)
  - `lib/scratchbird/connection.rb:57` (`Connection#execute`/`#stream` autocommit gate via `begin_transaction_if_needed`)
  - `lib/scratchbird/connection.rb:78` (`Connection#execute_prepared`, `#stream_prepared` uses the same transaction gate as direct execution)
  - `lib/scratchbird/client.rb:42` (`Client#txn_id` reader + `#in_transaction?`)
  - `lib/scratchbird/client.rb:125` (`Client#begin_transaction`, `#commit`, `#rollback`)
  - `lib/scratchbird/client.rb:146` (`#savepoint`, `#release_savepoint`, `#rollback_to_savepoint`)
  - `lib/scratchbird/protocol.rb:300` (transaction payload builders)
- Lane-local test anchors:
  - `test/test_txn_exec_parity.rb:67` (`test_execute_starts_transaction_once_when_autocommit_disabled`)
  - `test/test_txn_exec_parity.rb:79` (`test_commit_and_rollback_reset_transaction_gate`)
  - `test/test_txn_exec_parity.rb:106` (`test_statement_execute_and_stream_use_connection_transaction_gate`)
  - `test/test_txn_exec_parity.rb:129` (`test_connection_savepoint_api_forwards_to_client`)
- Gaps / next actions:
  - Add wire-level tests that validate `txn_id` transitions from `READY` frames against a live server response sequence.
  - Add integration coverage for failure paths (for example commit/rollback behavior after server-side aborts).

## EXEC (JDBCBL: `EXEC`)

- Current status: `Partial`
- Lane-local source anchors:
  - `lib/scratchbird/sql.rb:12` (`Sql.normalize`, positional/named rewrite)
  - `lib/scratchbird/connection.rb:57` (`#execute`, `#query`, `#stream` with options forwarding and shared transaction gate)
  - `lib/scratchbird/connection.rb:73` (`#prepare`) and `lib/scratchbird/connection.rb:78` (`#execute_prepared`, `#stream_prepared`)
  - `lib/scratchbird/statement.rb:21` (`Statement#execute`, `#stream` delegates through connection gate)
  - `lib/scratchbird/client.rb:254` (`Client#query`, `#stream`)
  - `lib/scratchbird/client.rb:266` (`Client#prepare`, `#execute`, `#execute_stream`)
  - `lib/scratchbird/client.rb:291` (`Client#deallocate`, explicit prepared-statement close protocol flow)
  - `lib/scratchbird/client.rb:298` (`Client#cancel`)
  - `lib/scratchbird/client.rb:705` (`execute_query_loop`) and `lib/scratchbird/client.rb:856` (`ResultStream`)
  - `lib/scratchbird/protocol.rb:379` (`parse_row_description`), `lib/scratchbird/protocol.rb:411` (`parse_data_row`), `lib/scratchbird/protocol.rb:442` (`parse_command_complete`)
- Lane-local test anchors:
  - `test/test_sql.rb:11` (`test_normalize_positional`)
  - `test/test_sql.rb:18` (`test_normalize_named`)
  - `test/test_sql.rb:25` (`test_normalize_binary`)
  - `test/test_txn_exec_parity.rb:94` (`test_query_and_stream_forward_options`)
  - `test/test_txn_exec_parity.rb:106` (`test_statement_execute_and_stream_use_connection_transaction_gate`)
  - `test/test_txn_exec_parity.rb:121` (`test_statement_execute_raises_when_closed`)
  - `test/test_txn_exec_parity.rb:140` (`test_statement_close_deallocates_prepared_handle`)
  - `test/test_integration.rb:24` (`test_prepare_bind`, env-gated parameter execution)
  - `test/test_integration.rb:50` (`test_cancel`, env-gated)
- Gaps / next actions:
  - Add deterministic coverage for `max_rows` portal suspend/resume and multi-frame stream continuation.
  - Add unit tests for `ResultStream#each_hash` and single-consumption lifecycle against mixed async/query frames.
  - Add live-wire sequencing assertions around `MSG_CLOSE_COMPLETE` behavior in integration coverage.

## META (JDBCBL: `META`)

- Current status: `Partial`
- Lane-local source anchors:
  - `lib/scratchbird/metadata.rb:11` (`Metadata` query constants and accessors for schemas/tables/columns/indexes/constraints/procedures/functions)
  - `lib/scratchbird/metadata.rb:74` (`schema_paths_for_navigation`, metadata-only schema path normalization/de-duplication with optional parent expansion mode)
  - `lib/scratchbird/metadata.rb:99` (`build_schema_tree`, recursive schema tree shaping with per-parent uniqueness and terminal-node tracking)
  - `lib/scratchbird/metadata.rb:131` (`expand_schema_metadata_rows`, metadata-row parent expansion with synthetic ancestor rows)
  - `lib/scratchbird/metadata.rb:160` (`build_database_default_metadata_rows`, database->default branch-style metadata row shaping)
  - `lib/scratchbird.rb:18` (exports metadata module via top-level require)
- Lane-local test anchors:
  - `test/test_metadata_recursive_schema.rb:11` (`test_database_default_branch_style_metadata_rows`)
  - `test/test_metadata_recursive_schema.rb:40` (`test_dotted_schema_parent_expansion`)
  - `test/test_metadata_recursive_schema.rb:64` (`test_tree_uniqueness_within_parent`)
  - `test/test_metadata_recursive_schema.rb:80` (`test_same_object_name_under_different_parents_is_preserved`)
- Gaps / next actions:
  - Add driver-level metadata execution APIs through `Connection`/`Client` (collection routing/restriction support is still helper-only in this lane).
  - Expand metadata family coverage toward full JDBCBL-META scope (catalog/key/privilege/type-oriented surfaces and richer DDL editor fields).
  - Add live integration assertions that validate metadata query payloads against fixture catalogs (current coverage is lane unit-level shaping).

## TYPE (JDBCBL: `TYPE`)

- Current status: `Partial`
- Lane-local source anchors:
  - `lib/scratchbird/types.rb:67` (`Types` OID map and format constants)
  - `lib/scratchbird/types.rb:128` (`Types.encode_param`)
  - `lib/scratchbird/types.rb:206` (`Types.decode`)
  - `lib/scratchbird/types.rb:260` (`Types.decode_binary_value`)
  - `lib/scratchbird/client.rb:314` (`Client#decode_row` delegates to `Types.decode`)
  - `lib/scratchbird/client.rb:758` (`send_extended_query` uses `Types.encode_param`)
- Lane-local test anchors:
  - `test/test_types.rb:11` (`test_decode_uuid`)
  - `test/test_types.rb:17` (`test_decode_array`)
  - `test/test_integration.rb:37` (`test_types_fixture`, env-gated)
- Gaps / next actions:
  - Expand unit tests across encode/decode matrix (numeric/date/time/json/jsonb/range/composite/vector/null/unknown OIDs).
  - Add round-trip assertions for bind parameters and result decoding for more than UUID/array fixtures.

## ERR (JDBCBL: `ERR`)

- Current status: `Partial`
- Lane-local source anchors:
  - `lib/scratchbird/errors.rb:9` (driver error classes)
  - `lib/scratchbird/errors.rb:35` (`ErrorMapper.from_sqlstate`)
  - `lib/scratchbird/client.rb:325` (`Client#handle_query_error`, maps wire errors to typed errors)
  - `lib/scratchbird/protocol.rb:501` (`parse_error_message`)
- Lane-local test anchors:
  - `test/test_integration.rb:50` (`test_cancel`) asserts an error occurs after cancel, but not SQLSTATE/class.
- Gaps / next actions:
  - Add unit tests for SQLSTATE-to-class mapping coverage in `ErrorMapper`.
  - Add parsing/mapping tests for wire error payload fields (`message`, `detail`, `hint`, `sqlstate`).

## RES (JDBCBL: `RES`)

- Current status: `Partial`
- Lane-local source anchors:
  - `lib/scratchbird/connection.rb:27` (`Connection#close`, `#closed?`)
  - `lib/scratchbird/connection.rb:85` (`Connection#close_prepared`)
  - `lib/scratchbird/statement.rb:31` (`Statement#close`, `#closed?`, best-effort prepared deallocation)
  - `lib/scratchbird/result.rb:11` (`Result` container/enumeration helpers)
  - `lib/scratchbird/client.rb:94` (`Client#close` cleanup path: socket, keepalive, leak guard)
  - `lib/scratchbird/client.rb:644` (`with_resilience` wrapper for circuit breaker + telemetry + keepalive)
  - `lib/scratchbird/client.rb:856` (`ResultStream` single-consumption iterator and rowcount finalization)
  - `lib/scratchbird/circuit_breaker.rb:4`, `lib/scratchbird/keepalive.rb:7`, `lib/scratchbird/telemetry.rb:6`, `lib/scratchbird/leak_detector.rb:4` (resilience helper implementations)
- Lane-local test anchors:
  - `test/test_integration.rb:11` / `:24` / `:37` (explicit `conn.close` in `ensure`; env-gated)
  - No dedicated unit tests for `Result`, `ResultStream`, or resource guard behavior.
- Gaps / next actions:
  - Add unit tests for idempotent close paths, stream single-consumption guard, and result iteration helpers.
  - Add direct unit tests for resilience helper wiring in `Client#initialize`/`#close` (circuit breaker, keepalive manager, leak detector, telemetry).
