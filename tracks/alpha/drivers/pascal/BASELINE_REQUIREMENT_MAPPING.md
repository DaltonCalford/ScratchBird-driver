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
  - `src/ScratchBird.Client.pas:374`, `src/ScratchBird.Client.pas:396`, `src/ScratchBird.Client.pas:406`, `src/ScratchBird.Client.pas:772`
  - `src/ScratchBird.Protocol.pas:362`, `src/ScratchBird.Protocol.pas:627`
- Lane-local test anchors:
  - `tests/ConfigTests.pas:38`, `tests/ConfigTests.pas:55`, `tests/ConfigTests.pas:61`
  - `tests/ConnectionAuthProtocolTests.pas:48`, `tests/ConnectionAuthProtocolTests.pas:59`, `tests/ConnectionAuthProtocolTests.pas:77`, `tests/ConnectionAuthProtocolTests.pas:98`, `tests/ConnectionAuthProtocolTests.pas:124`
  - `tests/TlsCryptoAndPolicyTests.pas:127`, `tests/TlsCryptoAndPolicyTests.pas:149`
  - `tests/IntegrationTest.pas:24`, `tests/IntegrationTest.pas:33`
- Gaps/next actions:
  - Add deterministic lane tests that exercise end-to-end manager-proxy handshake/auth success and failure against a controllable MCP fixture (`src/ScratchBird.Client.pas:772`).
  - Add deterministic lane tests for direct front-door end-to-end auth negotiation matrix (password/SCRAM) without relying on external environment setup.
  - Integration connect checks are env-gated and can be skipped (`tests/IntegrationTest.pas:24-28`).

## TXN (JDBCBL: TXN)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Client.pas:451`, `src/ScratchBird.Client.pas:457`, `src/ScratchBird.Client.pas:459`, `src/ScratchBird.Client.pas:477`, `src/ScratchBird.Client.pas:489`, `src/ScratchBird.Client.pas:501`, `src/ScratchBird.Client.pas:512`, `src/ScratchBird.Client.pas:523`
  - `src/ScratchBird.Client.pas:1243`, `src/ScratchBird.Client.pas:1249`, `src/ScratchBird.Client.pas:1255`
  - `src/ScratchBird.Protocol.pas:545`, `src/ScratchBird.Protocol.pas:553`, `src/ScratchBird.Protocol.pas:558`, `src/ScratchBird.Protocol.pas:563`, `src/ScratchBird.Protocol.pas:571`, `src/ScratchBird.Protocol.pas:576`
  - `src/ScratchBird.FireDAC.pas:93`, `src/ScratchBird.FireDAC.pas:98`, `src/ScratchBird.FireDAC.pas:103`
  - `src/ScratchBird.IBX.pas:91`, `src/ScratchBird.IBX.pas:96`, `src/ScratchBird.IBX.pas:101`
  - `src/ScratchBird.Zeos.pas:92`, `src/ScratchBird.Zeos.pas:97`, `src/ScratchBird.Zeos.pas:102`
  - `src/ScratchBird.SQLdb.pas:92`, `src/ScratchBird.SQLdb.pas:97`, `src/ScratchBird.SQLdb.pas:102`
- Lane-local test anchors:
  - `tests/TxnExecParityTests.pas:66`, `tests/TxnExecParityTests.pas:87`, `tests/TxnExecParityTests.pas:100`, `tests/TxnExecParityTests.pas:121`, `tests/TxnExecParityTests.pas:174`
- Gaps/next actions:
  - Add live transaction integration tests that validate begin/commit/rollback/savepoint behavior against a running server (current lane tests are local-only guardrail tests).
  - Adapter-level access to advanced transaction options is still limited; `BeginTransactionEx` remains client-only (`src/ScratchBird.Client.pas:451`).
  - Nested-begin rejection is covered locally, but transaction-state transitions are not yet asserted end-to-end against wire-reported READY states.

## EXEC (JDBCBL: EXEC)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Client.pas:642`, `src/ScratchBird.Client.pas:647`, `src/ScratchBird.Client.pas:680`, `src/ScratchBird.Client.pas:1243`, `src/ScratchBird.Client.pas:1262`
  - `src/ScratchBird.Client.pas:274`, `src/ScratchBird.Common.pas:111`
  - `src/ScratchBird.Sql.pas:50`, `src/ScratchBird.Sql.pas:114`, `src/ScratchBird.Sql.pas:151`, `src/ScratchBird.Sql.pas:157`
  - `src/ScratchBird.FireDAC.pas:186`, `src/ScratchBird.IBX.pas:120`, `src/ScratchBird.Zeos.pas:121`, `src/ScratchBird.SQLdb.pas:121`
- Lane-local test anchors:
  - `tests/TxnExecParityTests.pas:142`, `tests/TxnExecParityTests.pas:193`
  - `tests/SqlTests.pas:42`, `tests/SqlTests.pas:54`, `tests/SqlTests.pas:63`
  - `tests/IntegrationTest.pas:33`, `tests/IntegrationTest.pas:40`, `tests/IntegrationTest.pas:53`, `tests/IntegrationTest.pas:54`
- Gaps/next actions:
  - Adapter `Prepare` methods are currently empty (`src/ScratchBird.FireDAC.pas:127`, `src/ScratchBird.IBX.pas:145`, `src/ScratchBird.Zeos.pas:146`, `src/ScratchBird.SQLdb.pas:146`).
  - Add tests for stream control/backpressure path (`src/ScratchBird.Client.pas:618`).
  - Add dedicated API coverage for batch execution, multi-result traversal, and generated-key retrieval (currently not first-class in this lane).

## META (JDBCBL: META)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Metadata.pas:64`, `src/ScratchBird.Metadata.pas:65`, `src/ScratchBird.Metadata.pas:66`, `src/ScratchBird.Metadata.pas:67`
  - `src/ScratchBird.Metadata.pas:68`, `src/ScratchBird.Metadata.pas:69`, `src/ScratchBird.Metadata.pas:70`, `src/ScratchBird.Metadata.pas:71`
  - `src/ScratchBird.Metadata.pas:283` (`ExpandSchemaPaths`, dotted parent expansion + de-duplication)
  - `src/ScratchBird.Metadata.pas:318` (`ListMetadataSchemaPaths`, metadata-row schema extraction + optional parent expansion)
  - `src/ScratchBird.Metadata.pas:346` (`ExpandSchemaMetadataRows`, synthetic ancestor-row shaping for recursive navigation)
  - `src/ScratchBird.Metadata.pas:517` (`BuildMetadataSchemaTree`, recursive schema tree with per-parent uniqueness and terminal-node semantics)
- Lane-local test anchors:
  - `tests/MetadataRecursiveSchemaTests.pas:123` (database/default branch-style metadata-row expansion)
  - `tests/MetadataRecursiveSchemaTests.pas:158` (dotted parent expansion ordering + uniqueness)
  - `tests/MetadataRecursiveSchemaTests.pas:178` (per-parent uniqueness semantics)
  - `tests/MetadataRecursiveSchemaTests.pas:202` (same leaf name under different parents)
- Gaps/next actions:
  - Add client/adapter metadata APIs that execute these metadata helpers for first-class metadata collections.
  - Add metadata integration tests for schema/table/column/index/constraint/routine query paths.
  - Add broader JDBC metadata-family parity coverage (catalog/key/privilege/type families and restriction mapping).

## TYPE (JDBCBL: TYPE)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Types.pas:184`, `src/ScratchBird.Types.pas:612`, `src/ScratchBird.Types.pas:733`, `src/ScratchBird.Types.pas:975`, `src/ScratchBird.Types.pas:1041`
  - `src/ScratchBird.Types.pas:53`, `src/ScratchBird.Types.pas:57`, `src/ScratchBird.Types.pas:66`
  - `src/ScratchBird.Client.pas:274`
- Lane-local test anchors:
  - `tests/IntegrationTest.pas:45`
- Gaps/next actions:
  - Add lane-local codec tests that assert per-OID encode/decode behavior (beyond fixture-presence checks).
  - `OID_TIMETZ` is declared (`src/ScratchBird.Types.pas:53`) but has no explicit decode branch in `DecodeValue` (`src/ScratchBird.Types.pas:1041` onward).
  - Object geometry encode path uses `OID_POINT` (`src/ScratchBird.Types.pas:773`, `src/ScratchBird.Types.pas:801`); broaden this if other geometry OIDs are required.

## ERR (JDBCBL: ERR)
- Current status: Implemented
- Lane-local source anchors:
  - `src/ScratchBird.Errors.pas:47`, `src/ScratchBird.Errors.pas:55`
  - `src/ScratchBird.Protocol.pas:821`
  - `src/ScratchBird.Client.pas:997`
- Lane-local test anchors:
  - No dedicated SQLSTATE-mapping unit tests in `tests/`.
- Gaps/next actions:
  - Add targeted tests for `MapSqlState` category mapping in `src/ScratchBird.Errors.pas`.
  - `BuildQueryError` parses severity from wire payload but categorization is SQLSTATE-driven (`src/ScratchBird.Client.pas:997`).

## RES (JDBCBL: RES)
- Current status: Partial
- Lane-local source anchors:
  - `src/ScratchBird.Client.pas:411`, `src/ScratchBird.Client.pas:663`, `src/ScratchBird.Client.pas:1234`
  - `src/ScratchBird.Client.pas:1205`, `src/SBCircuitBreaker.pas:136`, `src/SBCircuitBreaker.pas:173`, `src/SBCircuitBreaker.pas:197`
  - `src/SBKeepalive.pas:129`
  - `src/SBKeepalive.pas:178`, `src/SBKeepalive.pas:183`, `src/SBKeepalive.pas:210`
  - `src/SBLeakDetector.pas:130`, `src/SBLeakDetector.pas:135`, `src/SBLeakDetector.pas:162`
  - `src/ScratchBird.Common.pas:45`, `src/ScratchBird.Common.pas:111`, `src/ScratchBird.Common.pas:117`
- Lane-local test anchors:
  - `tests/IntegrationTest.pas:50`, `tests/IntegrationTest.pas:54`, `tests/IntegrationTest.pas:60`
- Gaps/next actions:
  - Implement placeholder keepalive manager and leak detector list/check routines (`src/SBKeepalive.pas`, `src/SBLeakDetector.pas` anchors above).
  - Add explicit resource-lifecycle tests for cancel/close/stream ownership behavior.
