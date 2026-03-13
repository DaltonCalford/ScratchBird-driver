# PHP S0 Baseline Requirement Mapping

Status key:
- Implemented: behavior exists with direct lane test evidence.
- Partial: behavior exists but has explicit limits and/or thin test coverage in this lane.

| PHPBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| CONN | JDBCBL-CONN | Implemented | [src/Config.php](src/Config.php), [src/Connection.php](src/Connection.php), [tests/ConfigTest.php](tests/ConfigTest.php), [tests/ProtocolConnAuthTest.php](tests/ProtocolConnAuthTest.php), [tests/ConnectionConnTest.php](tests/ConnectionConnTest.php), [tests/IntegrationTest.php](tests/IntegrationTest.php) |
| TXN | JDBCBL-TXN | Implemented | [src/Connection.php](src/Connection.php), [src/ScratchBirdPDO.php](src/ScratchBirdPDO.php), [tests/ConnectionTxnExecTest.php](tests/ConnectionTxnExecTest.php), [tests/IntegrationTest.php](tests/IntegrationTest.php) |
| EXEC | JDBCBL-EXEC | Implemented | [src/Connection.php](src/Connection.php), [src/Statement.php](src/Statement.php), [src/ResultStream.php](src/ResultStream.php), [src/Sql.php](src/Sql.php), [src/ScratchBirdPDO.php](src/ScratchBirdPDO.php), [tests/ConnectionTxnExecTest.php](tests/ConnectionTxnExecTest.php), [tests/SqlTest.php](tests/SqlTest.php), [tests/IntegrationTest.php](tests/IntegrationTest.php) |
| META | JDBCBL-META | Implemented | [src/Metadata.php](src/Metadata.php), [src/Connection.php](src/Connection.php), [src/ScratchBirdPDO.php](src/ScratchBirdPDO.php), [tests/MetadataRecursiveSchemaTest.php](tests/MetadataRecursiveSchemaTest.php), [tests/MetadataExecutionTest.php](tests/MetadataExecutionTest.php), [tests/IntegrationTest.php](tests/IntegrationTest.php) |
| TYPE | JDBCBL-TYPE | Implemented | [src/TypeDecoder.php](src/TypeDecoder.php), [src/ResultStream.php](src/ResultStream.php), [tests/TypeDecoderTest.php](tests/TypeDecoderTest.php), [tests/ConnectionTxnExecTest.php](tests/ConnectionTxnExecTest.php), [tests/IntegrationTest.php](tests/IntegrationTest.php) |
| ERR | JDBCBL-ERR | Implemented | [src/Errors.php](src/Errors.php), [src/Connection.php](src/Connection.php), [tests/ErrorsTest.php](tests/ErrorsTest.php), [tests/ConnectionTxnExecTest.php](tests/ConnectionTxnExecTest.php), [tests/IntegrationTest.php](tests/IntegrationTest.php) |
| RES | JDBCBL-RES | Implemented | [src/ResultStream.php](src/ResultStream.php), [src/Statement.php](src/Statement.php), [src/Connection.php](src/Connection.php), [tests/ConnectionTxnExecTest.php](tests/ConnectionTxnExecTest.php), [tests/IntegrationTest.php](tests/IntegrationTest.php) |

## Notes on current status

- CONN: DSN alias parsing, native protocol/front-door normalization, TLS/direct and manager-proxy connect flows, compatibility connection options (`sslmode=disable`, `binary_transfer=false`, `compression=zstd`), manager fast-path/challenge-path flows, and typed auth/connection failures are covered by deterministic lane tests plus env-gated integration probes.
- TXN: Begin/commit/rollback/savepoint/release/rollback-to semantics and transaction guard behavior are implemented with READY-driven state synchronization, including server-error-plus-ready abort handling and integration lifecycle checks.
- EXEC: SQL normalization/callable execution, batch summaries, multi-result traversal, generated keys, portal suspend/resume continuation, and statement rowset traversal are covered by deterministic wire-fixture tests and env-gated runtime checks.
- META: Metadata collection mapping, alias normalization, recursive schema-tree shaping, restriction filtering, and exposed PDO wrappers (`getSchema`, `getSchemaTree`) are implemented with lane tests and live-shape integration probes.
- TYPE: Type encode/decode coverage includes core scalar, temporal, JSON/JSONB, UUID, monetary/numeric, range/composite, geometry, and representative runtime roundtrip checks with expanded OID matrix assertions.
- ERR: SQLSTATE-class and SQLSTATE-specific exception mapping, wire detail/hint propagation, and connection/statement errorInfo paths are validated in dedicated lane tests and integration error mapping checks.
- RES: Result-stream lifecycle, multi-result boundaries, cursor completion, close semantics, and connection resource cleanup are validated through deterministic execution tests and integration coverage.
