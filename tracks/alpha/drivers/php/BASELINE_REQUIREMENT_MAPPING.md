# PHP S0 Baseline Requirement Mapping

Status key:
- Implemented: behavior exists with direct lane test evidence.
- Partial: behavior exists but has explicit limits and/or thin test coverage in this lane.

| PHPBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| CONN | JDBCBL-CONN | Partial | [src/Config.php#L178](src/Config.php#L178), [src/Connection.php#L460](src/Connection.php#L460), [src/Connection.php#L689](src/Connection.php#L689), [tests/ConfigTest.php#L52](tests/ConfigTest.php#L52), [tests/ProtocolConnAuthTest.php#L19](tests/ProtocolConnAuthTest.php#L19), [tests/ConnectionConnTest.php#L21](tests/ConnectionConnTest.php#L21) |
| TXN | JDBCBL-TXN | Partial | [src/Connection.php#L120](src/Connection.php#L120), [src/Connection.php#L137](src/Connection.php#L137), [src/Connection.php#L155](src/Connection.php#L155), [src/Connection.php#L893](src/Connection.php#L893), [src/ScratchBirdPDO.php#L53](src/ScratchBirdPDO.php#L53), [tests/ConnectionTxnExecTest.php#L21](tests/ConnectionTxnExecTest.php#L21) |
| EXEC | JDBCBL-EXEC | Partial | [src/Connection.php#L106](src/Connection.php#L106), [src/Connection.php#L338](src/Connection.php#L338), [src/Statement.php#L45](src/Statement.php#L45), [src/Sql.php#L16](src/Sql.php#L16), [tests/ConnectionTxnExecTest.php#L82](tests/ConnectionTxnExecTest.php#L82), [tests/IntegrationTest.php#L17](tests/IntegrationTest.php#L17), [tests/SqlTest.php#L17](tests/SqlTest.php#L17) |
| META | JDBCBL-META | Partial | [src/Metadata.php#L129](src/Metadata.php#L129), [src/Metadata.php#L151](src/Metadata.php#L151), [src/Metadata.php#L193](src/Metadata.php#L193), [tests/MetadataRecursiveSchemaTest.php#L19](tests/MetadataRecursiveSchemaTest.php#L19), [tests/MetadataRecursiveSchemaTest.php#L43](tests/MetadataRecursiveSchemaTest.php#L43), [tests/MetadataRecursiveSchemaTest.php#L68](tests/MetadataRecursiveSchemaTest.php#L68), [tests/MetadataRecursiveSchemaTest.php#L90](tests/MetadataRecursiveSchemaTest.php#L90), [tests/metadata_recursive_schema_smoke.php#L52](tests/metadata_recursive_schema_smoke.php#L52) |
| TYPE | JDBCBL-TYPE | Partial | [src/TypeDecoder.php#L146](src/TypeDecoder.php#L146), [src/TypeDecoder.php#L214](src/TypeDecoder.php#L214), [src/TypeDecoder.php#L231](src/TypeDecoder.php#L231), [src/TypeDecoder.php#L272](src/TypeDecoder.php#L272), [src/ResultStream.php#L64](src/ResultStream.php#L64), [tests/IntegrationTest.php#L42](tests/IntegrationTest.php#L42) |
| ERR | JDBCBL-ERR | Partial | [src/Errors.php#L14](src/Errors.php#L14), [src/Errors.php#L44](src/Errors.php#L44), [src/Connection.php#L891](src/Connection.php#L891), [src/Connection.php#L897](src/Connection.php#L897), [src/ResultStream.php#L53](src/ResultStream.php#L53), [src/ScratchBirdPDO.php#L23](src/ScratchBirdPDO.php#L23) |
| RES | JDBCBL-RES | Implemented | [src/ResultStream.php#L27](src/ResultStream.php#L27), [src/ResultStream.php#L42](src/ResultStream.php#L42), [src/Statement.php#L55](src/Statement.php#L55), [src/Statement.php#L69](src/Statement.php#L69), [src/Statement.php#L82](src/Statement.php#L82), [tests/IntegrationTest.php#L24](tests/IntegrationTest.php#L24), [tests/IntegrationTest.php#L65](tests/IntegrationTest.php#L65) |

## Notes on current status

- CONN: Core DSN parse, TCP/TLS connect, startup/auth payload handling, and manager-proxy negotiation exist with targeted unit tests. Status remains `Partial` because live auth-mode matrix and manager-proxy integration coverage are still thin in lane-local tests.
- TXN: Begin/commit/rollback/savepoint paths now have dedicated lane-local transaction guard and lifecycle tests; status remains `Partial` because integration coverage across server-side transaction semantics is still limited.
- META: Lane metadata helpers now include metadata-only recursive schema tree shaping, dotted parent expansion mode, branch-style metadata row expansion, and per-parent uniqueness behavior with focused lane tests; status remains `Partial` because the driver still lacks a first-class executable metadata API that covers full JDBC metadata families (catalog/key/privilege/type) and live metadata integration assertions.
- TYPE: Codec covers many scalar and advanced OIDs, but lane tests only assert fixture availability, not per-type value fidelity.
- EXEC: `exec()` row-count and error-path behavior is now unit-tested via wire fixtures, but broader JDBC-style multi-result and advanced execution semantics remain only partially validated.
- ERR: SQLSTATE-to-exception mapping and last-error recording exist; PDO-style `prepare/query` wrappers return `false` on throw.
