# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope
- Lane-local S0 artifact for `tracks/alpha/drivers/pascal` only.
- Maps this lane's current capability coverage to JDBCBL groups: `CONN`, `TXN`, `EXEC`, `META`, `TYPE`, `ERR`, `RES`.
- All statements below are anchored to lane-local source and test files.

## CONN (JDBCBL: CONN)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Config.pas:55`, `src/ScratchBird.Config.pas:106`, `src/ScratchBird.Config.pas:324`
  - `src/ScratchBird.Transport.Native.pas:51`, `src/ScratchBird.Transport.Native.pas:59`, `src/ScratchBird.Transport.Native.pas:82`
  - `src/ScratchBird.Tls.Context.pas:136`, `src/ScratchBird.Tls.Context.pas:303`, `src/ScratchBird.Tls.Context.pas:334`
  - `src/ScratchBird.Tls.X509.pas:72`, `src/ScratchBird.Tls.X509.pas:173`
  - `src/ScratchBird.Client.pas:449`, `src/ScratchBird.Client.pas:481`, `src/ScratchBird.Client.pas:1070`, `src/ScratchBird.Client.pas:1201`
  - `src/ScratchBird.Protocol.pas:362`, `src/ScratchBird.Protocol.pas:627`
- Lane-local test anchors:
  - `tests/ConfigTests.pas:38`, `tests/ConfigTests.pas:55`, `tests/ConfigTests.pas:61`
  - `tests/ConnectionManagerProxyTests.pas:250` (deterministic manager-proxy connect success path with MCP negotiation + password auth handshake)
  - `tests/ConnectionManagerProxyTests.pas:290` (deterministic manager-proxy auth failure path maps to `28000` and remains disconnected)
  - `tests/ConnectionDirectAuthMatrixTests.pas:166`, `tests/ConnectionDirectAuthMatrixTests.pas:194` (deterministic direct front-door password + SCRAM auth matrix coverage through READY state with startup/auth frame assertions)
  - `tests/ConnectionAuthProtocolTests.pas:48`, `tests/ConnectionAuthProtocolTests.pas:59`, `tests/ConnectionAuthProtocolTests.pas:77`, `tests/ConnectionAuthProtocolTests.pas:98`, `tests/ConnectionAuthProtocolTests.pas:124`
  - `tests/TlsCryptoAndPolicyTests.pas:127`, `tests/TlsCryptoAndPolicyTests.pas:149`
  - `tests/IntegrationTest.pas:24`, `tests/IntegrationTest.pas:33`
- Gaps/next actions:
  - Integration connect checks are env-gated and can be skipped (`tests/IntegrationTest.pas:24-28`).

## TXN (JDBCBL: TXN)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Client.pas:451`, `src/ScratchBird.Client.pas:457`, `src/ScratchBird.Client.pas:459`, `src/ScratchBird.Client.pas:477`, `src/ScratchBird.Client.pas:489`, `src/ScratchBird.Client.pas:501`, `src/ScratchBird.Client.pas:512`, `src/ScratchBird.Client.pas:523`
  - `src/ScratchBird.Client.pas:1243`, `src/ScratchBird.Client.pas:1249`, `src/ScratchBird.Client.pas:1255`
  - `src/ScratchBird.Protocol.pas:545`, `src/ScratchBird.Protocol.pas:553`, `src/ScratchBird.Protocol.pas:558`, `src/ScratchBird.Protocol.pas:563`, `src/ScratchBird.Protocol.pas:571`, `src/ScratchBird.Protocol.pas:576`
  - `src/ScratchBird.FireDAC.pas:120`, `src/ScratchBird.FireDAC.pas:125`, `src/ScratchBird.FireDAC.pas:131`, `src/ScratchBird.FireDAC.pas:136` (adapter transaction begin/begin-ex/commit/rollback forwarding)
  - `src/ScratchBird.IBX.pas:118`, `src/ScratchBird.IBX.pas:123`, `src/ScratchBird.IBX.pas:129`, `src/ScratchBird.IBX.pas:134` (adapter transaction begin/begin-ex/commit/rollback forwarding)
  - `src/ScratchBird.Zeos.pas:119`, `src/ScratchBird.Zeos.pas:124`, `src/ScratchBird.Zeos.pas:130`, `src/ScratchBird.Zeos.pas:135` (adapter transaction begin/begin-ex/commit/rollback forwarding)
  - `src/ScratchBird.SQLdb.pas:119`, `src/ScratchBird.SQLdb.pas:124`, `src/ScratchBird.SQLdb.pas:130`, `src/ScratchBird.SQLdb.pas:135` (adapter transaction begin/begin-ex/commit/rollback forwarding)
- Lane-local test anchors:
  - `tests/TxnExecParityTests.pas:66`, `tests/TxnExecParityTests.pas:87`, `tests/TxnExecParityTests.pas:100`, `tests/TxnExecParityTests.pas:121`, `tests/TxnExecParityTests.pas:174`
  - `tests/AdapterTransactionOptionsTests.pas:32`, `tests/AdapterTransactionOptionsTests.pas:50`, `tests/AdapterTransactionOptionsTests.pas:68`, `tests/AdapterTransactionOptionsTests.pas:86` (adapter `StartTransactionEx` disconnected guard parity across FireDAC/IBX/Zeos/SQLdb)
- Gaps/next actions:
  - Add live transaction integration tests that validate begin/commit/rollback/savepoint behavior against a running server (current lane tests are local-only guardrail tests).
  - Nested-begin rejection is covered locally, but transaction-state transitions are not yet asserted end-to-end against wire-reported READY states.

## EXEC (JDBCBL: EXEC)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Client.pas:656`, `src/ScratchBird.Client.pas:689`, `src/ScratchBird.Client.pas:713`, `src/ScratchBird.Client.pas:718`, `src/ScratchBird.Client.pas:1621`, `src/ScratchBird.Client.pas:1636`
  - `src/ScratchBird.Client.pas:175`, `src/ScratchBird.Client.pas:775` (first-class `ExecuteBatch` API with per-statement summary output)
  - `src/ScratchBird.Client.pas:176`, `src/ScratchBird.Client.pas:798` (first-class `QueryMulti` API with rowset materialization per statement)
  - `src/ScratchBird.Client.pas:374` (`MSG_PORTAL_SUSPENDED` resume path emits `MSG_EXECUTE` with current max rows)
  - `src/ScratchBird.Client.pas:48`, `src/ScratchBird.Client.pas:371`, `src/ScratchBird.Client.pas:372` (`TScratchBirdResultStream` generated-key exposure via `LastInsertId`/`HasLastInsertId` from `MSG_COMMAND_COMPLETE`)
  - `src/ScratchBird.Client.pas:274`, `src/ScratchBird.Common.pas:111`
  - `src/ScratchBird.Sql.pas:50`, `src/ScratchBird.Sql.pas:114`, `src/ScratchBird.Sql.pas:151`, `src/ScratchBird.Sql.pas:157`
  - `src/ScratchBird.FireDAC.pas:35`, `src/ScratchBird.FireDAC.pas:149`, `src/ScratchBird.FireDAC.pas:178` (adapter query prepare + exec routed through overridable execution hooks)
  - `src/ScratchBird.IBX.pas:34`, `src/ScratchBird.IBX.pas:167`, `src/ScratchBird.IBX.pas:196` (adapter query prepare + exec routed through overridable execution hooks)
  - `src/ScratchBird.Zeos.pas:34`, `src/ScratchBird.Zeos.pas:168`, `src/ScratchBird.Zeos.pas:197` (adapter query prepare + exec routed through overridable execution hooks)
  - `src/ScratchBird.SQLdb.pas:34`, `src/ScratchBird.SQLdb.pas:168`, `src/ScratchBird.SQLdb.pas:197` (adapter query prepare + exec routed through overridable execution hooks)
- Lane-local test anchors:
  - `tests/BatchExecutionTests.pas:200` (`ExecuteBatch` returns per-statement rows/tag/generated-key summaries and emits expected wire query payloads)
  - `tests/BatchExecutionTests.pas:244` (`ExecuteBatch` preserves SQL blank-text guard behavior with `42601`)
  - `tests/QueryMultiTests.pas:269` (`QueryMulti` materializes per-statement rowsets including column/row data and generated-key metadata)
  - `tests/QueryMultiTests.pas:320` (`QueryMulti` preserves SQL blank-text guard behavior with `42601`)
  - `tests/StreamControlBackpressureTests.pas:200` (client `StreamControl` emits `MSG_STREAM_CONTROL` with encoded window/timeout payload)
  - `tests/StreamControlBackpressureTests.pas:221` (`MSG_PORTAL_SUSPENDED` read loop triggers `MSG_EXECUTE` resume/backpressure follow-up)
  - `tests/StreamControlBackpressureTests.pas:257` (result stream captures generated key metadata via `LastInsertId`/`HasLastInsertId`)
  - `tests/AdapterPrepareLifecycleTests.pas:146` (adapter prepare guardrails for missing connection/database assignment)
  - `tests/AdapterPrepareLifecycleTests.pas:218` (FireDAC prepare snapshot and normalized parameter ordering reuse on exec)
  - `tests/AdapterPrepareLifecycleTests.pas:247` (IBX prepare snapshot and normalized parameter ordering reuse on exec)
  - `tests/AdapterPrepareLifecycleTests.pas:276` (Zeos prepare snapshot and normalized parameter ordering reuse on exec)
  - `tests/AdapterPrepareLifecycleTests.pas:305` (SQLdb prepare snapshot and normalized parameter ordering reuse on exec)
  - `tests/TxnExecParityTests.pas:142`, `tests/TxnExecParityTests.pas:193`
  - `tests/SqlTests.pas:42`, `tests/SqlTests.pas:54`, `tests/SqlTests.pas:63`
  - `tests/IntegrationTest.pas:33`, `tests/IntegrationTest.pas:40`, `tests/IntegrationTest.pas:53`, `tests/IntegrationTest.pas:54`
- Gaps/next actions:
  - Add live integration assertions for batch and multi-result execution APIs against a running server (current coverage for these APIs is deterministic lane-local).

## META (JDBCBL: META)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Metadata.pas:160` (`NormalizeMetadataCollectionName`, alias normalization across schema/table/index/constraint/routine/catalog/key/privilege/type metadata families)
  - `src/ScratchBird.Metadata.pas:184` (`ResolveMetadataCollectionQuery`, metadata collection to SQL resolution)
  - `src/ScratchBird.Metadata.pas:694` (`FilterMetadataRowsByRestrictions`, collection-scoped restriction filtering with wildcard and null semantics)
  - `src/ScratchBird.Metadata.pas:808`, `src/ScratchBird.Metadata.pas:813`, `src/ScratchBird.Metadata.pas:818`, `src/ScratchBird.Metadata.pas:823`, `src/ScratchBird.Metadata.pas:828`, `src/ScratchBird.Metadata.pas:833`, `src/ScratchBird.Metadata.pas:838` (routines/catalogs/primary_keys/foreign_keys/table_privileges/column_privileges/type_info query builders)
  - `src/ScratchBird.Metadata.pas:843` (`ExpandSchemaPaths`, dotted parent expansion + de-duplication)
  - `src/ScratchBird.Metadata.pas:878` (`ListMetadataSchemaPaths`, metadata-row schema extraction + optional parent expansion)
  - `src/ScratchBird.Metadata.pas:906` (`ExpandSchemaMetadataRows`, synthetic ancestor-row shaping for recursive navigation)
  - `src/ScratchBird.Metadata.pas:1077` (`BuildMetadataSchemaTree`, recursive schema tree with per-parent uniqueness and terminal-node semantics)
  - `src/ScratchBird.Client.pas:724`, `src/ScratchBird.Client.pas:729` (generic client metadata stream API via `QueryMetadata`/`GetSchema`)
  - `src/ScratchBird.Client.pas:734`, `src/ScratchBird.Client.pas:742`, `src/ScratchBird.Client.pas:779`, `src/ScratchBird.Client.pas:784` (materialized metadata-row API with optional restrictions via `QueryMetadataRows`/`GetSchemaRows`)
  - `src/ScratchBird.Client.pas:789`, `src/ScratchBird.Client.pas:829`, `src/ScratchBird.Client.pas:854` (typed metadata wrapper methods for catalogs/routines/type_info)
  - `src/ScratchBird.FireDAC.pas:148`, `src/ScratchBird.FireDAC.pas:158`, `src/ScratchBird.FireDAC.pas:178`, `src/ScratchBird.FireDAC.pas:243` (adapter-level metadata stream/rows/typed wrapper forwarding)
  - `src/ScratchBird.IBX.pas:141`, `src/ScratchBird.IBX.pas:151`, `src/ScratchBird.IBX.pas:171`, `src/ScratchBird.IBX.pas:236` (adapter-level metadata stream/rows/typed wrapper forwarding)
  - `src/ScratchBird.Zeos.pas:142`, `src/ScratchBird.Zeos.pas:152`, `src/ScratchBird.Zeos.pas:172`, `src/ScratchBird.Zeos.pas:237` (adapter-level metadata stream/rows/typed wrapper forwarding)
  - `src/ScratchBird.SQLdb.pas:142`, `src/ScratchBird.SQLdb.pas:152`, `src/ScratchBird.SQLdb.pas:172`, `src/ScratchBird.SQLdb.pas:237` (adapter-level metadata stream/rows/typed wrapper forwarding)
- Lane-local test anchors:
  - `tests/AdapterMetadataApiTests.pas:33`, `tests/AdapterMetadataApiTests.pas:122`, `tests/AdapterMetadataApiTests.pas:211`, `tests/AdapterMetadataApiTests.pas:300` (adapter metadata API disconnected/not-supported guard and forwarding coverage across FireDAC/IBX/Zeos/SQLdb)
  - `tests/MetadataRecursiveSchemaTests.pas:129` (database/default branch-style metadata-row expansion)
  - `tests/MetadataRecursiveSchemaTests.pas:164` (dotted parent expansion ordering + uniqueness)
  - `tests/MetadataRecursiveSchemaTests.pas:184` (per-parent uniqueness semantics)
  - `tests/MetadataRecursiveSchemaTests.pas:208` (same leaf name under different parents)
  - `tests/MetadataRecursiveSchemaTests.pas:234` (metadata collection alias/query resolution coverage including catalogs/keys/privileges/type_info/routines)
  - `tests/MetadataRecursiveSchemaTests.pas:274` (restriction filtering coverage for aliases/wildcards/null semantics and unsupported restriction ignore behavior)
  - `tests/MetadataRecursiveSchemaTests.pas:338` (client metadata stream API guards: unsupported collection => `0A000`, disconnected supported collection => `08003`)
  - `tests/MetadataRecursiveSchemaTests.pas:370` (client metadata rows API guards for unsupported/disconnected paths)
  - `tests/MetadataRecursiveSchemaTests.pas:399` (typed metadata wrapper API guards on disconnected client)
  - `tests/MetadataExecutionFlowTests.pas:220`, `tests/MetadataExecutionFlowTests.pas:277` (deterministic metadata execution flow coverage for schema/table/column/index/constraint/routine wrapper query paths and restriction-aware `QueryMetadataRows` materialization)
- Gaps/next actions:
  - Add live metadata integration assertions against a running server for schema/table/column/index/constraint/routine query paths.
  - Extend result-shape parity fields to align more tightly with JDBC metadata contracts across collection families.

## TYPE (JDBCBL: TYPE)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Types.pas:53`, `src/ScratchBird.Types.pas:57`, `src/ScratchBird.Types.pas:66`
  - `src/ScratchBird.Types.pas:523`, `src/ScratchBird.Types.pas:532` (`TIMETZ` encode helpers including zone-offset payload handling)
  - `src/ScratchBird.Types.pas:752`, `src/ScratchBird.Types.pas:923` (`EncodeParam` scalar/array type routing including `TIMETZ` variant-array encoding)
  - `src/ScratchBird.Types.pas:991`, `src/ScratchBird.Types.pas:1097` (`TIMETZ` decode and per-OID decode dispatch)
  - `src/ScratchBird.Client.pas:274`
- Lane-local test anchors:
  - `tests/TypesCodecTests.pas:131` (scalar encode/decode anchors: bool/uuid/vector/jsonb/composite/unknown heuristics)
  - `tests/TypesCodecTests.pas:237` (`TIMETZ` decode coverage for 12-byte payload normalization and zone-offset conversion)
  - `tests/TypesCodecTests.pas:255` (`TIMETZ` backward-compatible 8-byte decode defaulting to UTC offset)
  - `tests/TypesCodecTests.pas:271` (`TIMETZ` encode payload shape + sign semantics for zone displacement)
  - `tests/IntegrationTest.pas:45`
- Gaps/next actions:
  - Expand deterministic lane-local per-OID matrix beyond representative coverage to full wire-type fidelity (current tests cover key scalar/advanced paths but not exhaustive OID matrix).
  - Integration type fixture validation remains env-gated and can be skipped (`tests/IntegrationTest.pas:24-28`).
  - Object geometry encode path uses `OID_POINT` (`src/ScratchBird.Types.pas:793`, `src/ScratchBird.Types.pas:821`); broaden this if other geometry OIDs are required.

## ERR (JDBCBL: ERR)
- Current status: Implemented
- Lane-local source anchors:
  - `src/ScratchBird.Errors.pas:47`, `src/ScratchBird.Errors.pas:55`
  - `src/ScratchBird.Protocol.pas:821`
  - `src/ScratchBird.Client.pas:997`
- Lane-local test anchors:
  - `tests/ErrorMappingTests.pas:40` (`MapSqlState` category assertions preserve SQLSTATE/detail/hint metadata)
  - `tests/ErrorMappingTests.pas:55` (category mapping matrix: warning/no-data/connection/not-supported/data/integrity/auth/txn/syntax/resource/limit/operator/system/internal)
  - `tests/ErrorMappingTests.pas:73` (fallback behavior for unknown SQLSTATE class)
  - `tests/ErrorMappingTests.pas:78` (fallback behavior for invalid SQLSTATE length)
- Gaps/next actions:
  - `BuildQueryError` parses severity from wire payload but categorization is SQLSTATE-driven (`src/ScratchBird.Client.pas:997`).

## RES (JDBCBL: RES)
- Current status: Implemented
- Lane-local source anchors:
  - `src/ScratchBird.Client.pas:375`, `src/ScratchBird.Client.pas:385`, `src/ScratchBird.Client.pas:435`, `src/ScratchBird.Client.pas:448`, `src/ScratchBird.Client.pas:1426`
  - `src/SBCircuitBreaker.pas:136`, `src/SBCircuitBreaker.pas:173`, `src/SBCircuitBreaker.pas:197`
  - `src/SBKeepalive.pas:55`, `src/SBKeepalive.pas:177`, `src/SBKeepalive.pas:205`, `src/SBKeepalive.pas:264`
  - `src/SBLeakDetector.pas:40`, `src/SBLeakDetector.pas:148`, `src/SBLeakDetector.pas:193`, `src/SBLeakDetector.pas:253`
  - `src/ScratchBird.Common.pas:45`, `src/ScratchBird.Common.pas:111`, `src/ScratchBird.Common.pas:117`
- Lane-local test anchors:
  - `tests/ResourceResilienceTests.pas:69` (keepalive tracker idle-window validation and `MarkActive` reset behavior)
  - `tests/ResourceResilienceTests.pas:92` (keepalive manager register/update/unregister plus idle pinger invocation)
  - `tests/ResourceResilienceTests.pas:126` (checkout metadata capture semantics)
  - `tests/ResourceResilienceTests.pas:139` (leak detector checkout/checkin replacement and active-count lifecycle)
  - `tests/ResourceResilienceTests.pas:168` (leak detector background thread start/stop lifecycle)
  - `tests/IntegrationTest.pas:50`, `tests/IntegrationTest.pas:54`, `tests/IntegrationTest.pas:60`
- Gaps/next actions:
  - Add live integration assertions for keepalive/leak behavior under real network disruption and reconnect scenarios (current coverage is deterministic lane-local behavior and lifecycle tests).
