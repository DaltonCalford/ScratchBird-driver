# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope

- This is a lane-local S0 artifact for `tracks/beta/drivers/cpp` only.
- Mapping evidence is restricted to files under this lane's `include/`, `src/`, and `tests/`.

## CONN (JDBCBL: CONN)

- Current status: `Partial`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`sb_connect`, `sb_disconnect`, `sb_ping`, `sb_set_option`, `sb_is_healthy`)
  - `src/network_client.cpp` (`resolveConnectionAddress`, `NetworkClient::connect`, `NetworkClient::handshake`)
  - `src/driver_config.cpp` (`parseDriverConnectionString`, `applyDriverDefaultsFromEnv`)
  - `src/network_client.cpp` now routes `transport_mode=local_ipc` + `ipc_method=pipe` through local loopback fallback instead of hard-failing.
  - `src/network_client.cpp` now fail-fast validates `manager_proxy` token presence and `auth_method_id` namespace before dialing.
- Lane-local test anchors:
  - `tests/test_driver_defaults.cpp` (`ParsesManagerProxyConnectionParams`, `ParsesLocalIpcTransportParams`, `ManagedTransportSetsManagerProxyFrontDoor`, auth pinning tests)
  - `tests/test_driver_connectivity.cpp` (`ConnectsToLocalListener`, `ConnectsWithPasswordAuthChallengeAndCarriesAuthParams`, `ConnectsWithLocalIpcPipeFallback`, `RejectsInvalidAuthMethodIdBeforeDial`, `RejectsManagerProxyModeWithoutTokenBeforeDial`)
- Gaps / next actions:
  - Add native OS named-pipe transport support; current `ipc_method=pipe` behavior is a local loopback fallback rather than true named-pipe I/O.
  - Add a true embedded transport implementation path; current code routes embedded mode through local IPC.
  - Add deterministic lane tests for full manager-proxy handshake/auth success and failure paths.

## TXN (JDBCBL: TXN)

- Current status: `Partial`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`sb_tx_begin`, `sb_tx_commit`, `sb_tx_rollback`)
  - `src/network_client.cpp` (`NetworkClient::beginTransaction`, `NetworkClient::commit`, `NetworkClient::rollback`, `mapProtocolError`, `drainUntilReady`)
  - `src/connection.cpp` (`Connection::beginTransaction`, `Connection::commit`, `Connection::rollback`, savepoint helpers)
- Lane-local test anchors:
  - `tests/test_driver_connectivity.cpp` (`TransactionRoundTripBeginCommitRollback`, `RollbackMapsNoActiveTransactionSqlState`)
- Gaps / next actions:
  - Add savepoint transaction tests (`SAVEPOINT`, `ROLLBACK TO`, `RELEASE`) at network/C API level.
  - Add coverage for additional transaction SQLSTATE mappings (for example `25P02`, `25006`) at the API boundary.
  - Decide whether savepoint helpers should be exposed in the C API (currently available in C++ `Connection` only).

## EXEC (JDBCBL: EXEC)

- Current status: `Partial`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`sb_execute`, `sb_query`, `sb_prepare`, `sb_bind_index`, `sb_bind_name`, `sb_execute_prepared`, `sb_cancel`, `sb_execute_sblr`, `sb_attach_*`)
  - `src/network_client.cpp` (`NetworkClient::executeQuery`, `prepare`, `executePrepared`, `prepareServerStatement`, `executeServerStatement`, `closeServerStatement`, `sendQueryCancel`, `executeSblr`, `streamControl`, terminal `Ready`/error sequence handling)
  - `src/protocol/sbwp_protocol.cpp` (payload/message builders consumed by execution paths)
- Lane-local test anchors:
  - `tests/test_driver_connectivity.cpp` (`QueryClearsCancelSequenceAfterReady`, `PrepareAndExecutePreparedRoundTrip`)
  - `tests/test_paging_payload.cpp` (`PagingConformance.BuildsStreamControlPayload`) covers stream-control payload encoding.
- Gaps / next actions:
  - Add lane tests for `executeServerStatement`/`closeServerStatement` and SBLR execution paths.
  - Add deterministic in-flight cancel behavior coverage (`sendQueryCancel` during active execution, not only post-ready state).
  - Add test coverage for attach create/detach/list execution paths.

## META (JDBCBL: META)

- Current status: `Partial`
- Lane-local source anchors:
  - `include/scratchbird/client/scratchbird_client.h` (`sb_metadata_*_query` helper SQL strings)
  - `include/scratchbird/client/metadata.h` (metadata-only schema path expansion/tree shaping APIs and row model)
  - `src/metadata.cpp` (`metadataSchemaPathsForNavigation`, `buildMetadataSchemaTree`, `buildMetadataSchemaTreeRows`)
  - `src/network_client.cpp` row-description parsing in execution paths populates column metadata
  - `src/scratchbird_client_c.cpp` (`sb_column_count`, `sb_get_column_meta`)
- Lane-local test anchors:
  - `tests/test_metadata_schema_tree.cpp` (`TreeRowsStartAtDatabaseAndExposeTopBranches`, `ParentExpansionAddsDottedSchemaAncestors`, `ParentDoesNotAllowDuplicateChildNames`, `SameLeafNameUnderDifferentParentsIsPreserved`)
- Gaps / next actions:
  - Add executable metadata API surfaces for broader JDBC families (catalog/key/privilege/type), not only helper SQL strings and shaping utilities.
  - Add tests validating metadata helper SQL strings and result-column metadata extraction (`sb_get_column_meta`) through concrete metadata query flows.
  - Add DDL-editor completeness validation for metadata payload fields beyond schema-tree shaping.

## TYPE (JDBCBL: TYPE)

- Current status: `Partial`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`map_type_oid`, `map_sb_type_to_oid`, `sb_value_get`, `apply_bind_value`, `build_param_value`)
  - `src/core/type_extractor.cpp` (date/time component extraction used by value decoding)
  - `src/scratchbird_client_c.cpp` returns `0` for some outbound OID defaults (`SB_TYPE_ARRAY`, `SB_TYPE_RANGE`) unless caller supplies `type_oid`.
- Lane-local test anchors:
  - `tests/test_type_mapping.cpp` (`MapsWireOidsToSbTypes`, `MapsSbTypesToWireOids`)
- Gaps / next actions:
  - Complete default outbound OID mapping for array/range cases where possible.
  - Add tests for full value encode/decode paths (`sb_value_get`, `build_param_value`, `apply_bind_value`) beyond OID mapping.

## ERR (JDBCBL: ERR)

- Current status: `Partial`
- Lane-local source anchors:
  - `src/network_client.cpp` (`mapProtocolError`) maps protocol SQLSTATE classes/messages to `core::Status` and writes SQLSTATE into `ErrorContext`
  - `src/scratchbird_client_c.cpp` (`map_status`, `set_error`) maps `core::Status` to C API `sb_error_code`
  - `src/core/sqlstate.cpp` (`statusToSQLState`)
  - `include/scratchbird/core/error_context.h` (`ErrorContext`, `setSQLState`, `SET_ERROR_CONTEXT`)
- Lane-local test anchors:
  - None found in `tests/` that exercise protocol-error to status/code/sqlstate mapping.
- Gaps / next actions:
  - Add unit tests for SQLSTATE -> `core::Status` -> `sb_error_code` mapping behavior.
  - Add regression tests for feature-not-supported, auth, and transaction-conflict mappings.

## RES (JDBCBL: RES)

- Current status: `Partial`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`sb_result_free`, `sb_prepared_free`, `sb_disconnect`) and connection lifecycle wiring for keepalive/leak tracking
  - `src/leak_detector.cpp` (`LeakDetector` and C wrappers `sb_leak_detector_*`)
  - `src/statement_cache.cpp` (`sb_stmt_cache_*`)
  - `include/scratchbird/client/pool.h` declares pool/retry/batch/health APIs with no implementation found under `src/`
- Lane-local test anchors:
  - None found in `tests/` for leak detector, statement cache eviction, or pool/retry lifecycle behavior.
- Gaps / next actions:
  - Implement or explicitly gate/remove undeployed pool/retry/batch/health APIs declared in `pool.h`.
  - Add lane tests for statement-cache eviction correctness and leak-detector checkout/checkin behavior.
