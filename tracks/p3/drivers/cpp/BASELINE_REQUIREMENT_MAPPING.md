# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope

- This is a lane-local S0 artifact for `tracks/p3/drivers/cpp` only.
- Mapping evidence is restricted to files under this lane's `include/`, `src/`, and `tests/`.

## CONN (JDBCBL: CONN)

- Current status: `Implemented`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`sb_connect`, `sb_disconnect`, `sb_ping`, `sb_set_option`, `sb_is_healthy`)
  - `src/network_client.cpp` (`resolveConnectionAddress`, `NetworkClient::connect`, `NetworkClient::handshake`)
  - `src/driver_config.cpp` (`parseDriverConnectionString`, `applyDriverDefaultsFromEnv`)
  - `src/network_client.cpp` and `src/driver_config.cpp` enforce IP-only transport (`inet_listener` or `managed`) and reject IPC/embedded connection settings before dial.
  - `src/network_client.cpp` now fail-fast validates `manager_proxy` token presence and `auth_method_id` namespace before dialing.
  - `src/driver_config.cpp` now accepts JDBC-compatible transport policy knobs (`binary_transfer=false`, `compression=zstd|off`) and rejects unsupported compression modes.
- Lane-local test anchors:
  - `tests/test_driver_defaults.cpp` (`ParsesManagerProxyConnectionParams`, `RejectsIpcTransportParams`, `RejectsUnixServerEndpoint`, `ManagedTransportSetsManagerProxyFrontDoor`, auth pinning tests)
  - `tests/test_driver_connectivity.cpp` (`ConnectsToLocalListener`, `ConnectsWithPasswordAuthChallengeAndCarriesAuthParams`, `ConnectsWithCompressionCompatibilityParamsFromDsn`, `RejectsIpcTransportBeforeDial`, `RejectsInvalidAuthMethodIdBeforeDial`, `RejectsManagerProxyModeWithoutTokenBeforeDial`, `ConnectsThroughManagerProxyHandshake`, `ManagerProxyAuthFailureMapsToInvalidAuthorization`)
- Gaps / next actions:
  - No open S0 CONN parity gaps. IP-only transport in this lane (`inet_listener` and `managed`) is intentional design scope, with driver-side IPC/embedded delegated to ScratchBird server/engine layers.

## TXN (JDBCBL: TXN)

- Current status: `Implemented`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`sb_tx_begin`, `sb_tx_commit`, `sb_tx_rollback`, `sb_tx_savepoint`, `sb_tx_release_savepoint`, `sb_tx_rollback_to`)
  - `src/network_client.cpp` (`NetworkClient::beginTransaction`, `NetworkClient::commit`, `NetworkClient::rollback`, `NetworkClient::savepoint`, `NetworkClient::releaseSavepoint`, `NetworkClient::rollbackToSavepoint`, `mapProtocolError`, `drainUntilReady`)
  - `src/connection.cpp` (`Connection::beginTransaction`, `Connection::commit`, `Connection::rollback`, savepoint helpers)
- Lane-local test anchors:
  - `tests/test_driver_connectivity.cpp` (`TransactionRoundTripBeginCommitRollback`, `SavepointRoundTripUsesTxnMessages`, `RollbackMapsNoActiveTransactionSqlState`, `CommitMapsReadOnlyAndAbortedSqlStates`, `CApiSavepointAndSqlStateMappingAtBoundary`)
- Gaps / next actions:
  - No open S0 TXN parity gaps.

## EXEC (JDBCBL: EXEC)

- Current status: `Implemented`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`sb_execute`, `sb_query`, `sb_prepare`, `sb_bind_index`, `sb_bind_name`, `sb_execute_prepared`, `sb_cancel`, `sb_execute_sblr`, `sb_attach_*`)
  - `src/network_client.cpp` (`NetworkClient::executeQuery`, `prepare`, `executePrepared`, `prepareServerStatement`, `executeServerStatement`, `closeServerStatement`, `sendQueryCancel`, `executeSblr`, `streamControl`, terminal `Ready`/error sequence handling)
  - `src/protocol/sbwp_protocol.cpp` (payload/message builders consumed by execution paths)
- Lane-local test anchors:
  - `tests/test_driver_connectivity.cpp` (`QueryClearsCancelSequenceAfterReady`, `CancelDuringInFlightQueryUsesCancelMessage`, `PrepareAndExecutePreparedRoundTrip`, `ExecuteServerStatementAndCloseRoundTrip`, `ExecuteSblrAndAttachFlowsRoundTrip`)
  - `tests/test_paging_payload.cpp` (`PagingConformance.BuildsStreamControlPayload`) covers stream-control payload encoding.
- Gaps / next actions:
  - No open S0 EXEC parity gaps.

## META (JDBCBL: META)

- Current status: `Implemented`
- Lane-local source anchors:
  - `include/scratchbird/client/scratchbird_client.h` (`sb_metadata_*_query` helper SQL strings)
  - `include/scratchbird/client/metadata.h` (schema tree shaping plus metadata collection normalization/query resolution APIs, DDL-editor schema payload shaping)
  - `src/metadata.cpp` (`metadataSchemaPathsForNavigation`, `buildMetadataSchemaTree`, `buildMetadataSchemaTreeRows`, `normalizeMetadataCollectionName`, `resolveMetadataCollectionQuery`, `buildMetadataDdlEditorSchemaPayloadJson`)
  - `src/scratchbird_client_c.cpp` (`sb_metadata_query`, `sb_metadata_schema_payload`)
  - `src/network_client.cpp` row-description parsing in execution paths populates column metadata
  - `src/scratchbird_client_c.cpp` (`sb_column_count`, `sb_get_column_meta`)
- Lane-local test anchors:
  - `tests/test_metadata_schema_tree.cpp` (`TreeRowsStartAtDatabaseAndExposeTopBranches`, `ParentExpansionAddsDottedSchemaAncestors`, `ParentDoesNotAllowDuplicateChildNames`, `SameLeafNameUnderDifferentParentsIsPreserved`, `NormalizesCollectionAliasesForExtendedFamilies`, `ResolvesExtendedCollectionQueries`, `RejectsUnsupportedCollection`, `BuildsDdlEditorSchemaPayloadJsonWithPatternAndParentExpansion`, `BuildsDdlEditorSchemaPayloadJsonWithoutPattern`)
  - `tests/test_type_mapping.cpp` (`MetadataQueryRequiresConnectionHandle`)
  - `tests/test_driver_connectivity.cpp` (`MetadataQueryReturnsColumnMetadataAndTypedValues`, `CApiMetadataSchemaPayloadIncludesDdlEditorFields`)
- Gaps / next actions:
  - No open S0 META parity gaps.

## TYPE (JDBCBL: TYPE)

- Current status: `Implemented`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`map_type_oid`, `map_sb_type_to_oid`, `sb_value_get`, `apply_bind_value`, `build_param_value`)
  - `src/core/type_extractor.cpp` (date/time component extraction used by value decoding)
  - `src/scratchbird_client_c.cpp` now supplies default outbound OIDs for `SB_TYPE_ARRAY`/`SB_TYPE_RANGE`.
- Lane-local test anchors:
  - `tests/test_type_mapping.cpp` (`MapsWireOidsToSbTypes`, `MapsSbTypesToWireOids`)
  - `tests/test_driver_connectivity.cpp` (`ArrayBindUsesDefaultOutboundOidMapping`, `MetadataQueryReturnsColumnMetadataAndTypedValues`)
- Gaps / next actions:
  - No open S0 TYPE parity gaps.

## ERR (JDBCBL: ERR)

- Current status: `Implemented`
- Lane-local source anchors:
  - `src/network_client.cpp` (`mapProtocolError`) maps protocol SQLSTATE classes/messages to `core::Status` and writes SQLSTATE into `ErrorContext`
  - `src/scratchbird_client_c.cpp` (`map_status`, `set_error`) maps `core::Status` to C API `sb_error_code`
  - `src/core/sqlstate.cpp` (`statusToSQLState`)
  - `include/scratchbird/core/error_context.h` (`ErrorContext`, `setSQLState`, `SET_ERROR_CONTEXT`)
- Lane-local test anchors:
  - `tests/test_driver_connectivity.cpp` (`RollbackMapsNoActiveTransactionSqlState`, `CommitMapsReadOnlyAndAbortedSqlStates`, `ManagerProxyAuthFailureMapsToInvalidAuthorization`, `FeatureNotSupportedMapsToCNotImplemented`, `CApiSavepointAndSqlStateMappingAtBoundary`)
- Gaps / next actions:
  - No open S0 ERR parity gaps.

## RES (JDBCBL: RES)

- Current status: `Implemented`
- Lane-local source anchors:
  - `src/scratchbird_client_c.cpp` (`sb_result_free`, `sb_prepared_free`, `sb_disconnect`) and connection lifecycle wiring for keepalive/leak tracking
  - `src/leak_detector.cpp` (`LeakDetector` and C wrappers `sb_leak_detector_*`)
  - `src/statement_cache.cpp` (`sb_stmt_cache_*`)
  - `src/pool.cpp` (`sb_pool_*`, `sb_with_retry`, `sb_query_with_retry`, `sb_execute_with_retry`, `sb_batch_execute`, `sb_bulk_insert`, `sb_connection_*`)
- Lane-local test anchors:
  - `tests/test_driver_connectivity.cpp` (`StatementCacheAndLeakDetectorLifecycle`, `PoolAcquireReleaseAndRetryUtility`, `BatchExecuteSupportsParameterizedOperations`, `BulkInsertExecutesPreparedInsertRows`)
- Gaps / next actions:
  - No open S0 RES parity gaps.
