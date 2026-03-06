# Node Baseline Requirement Mapping

Mapping of NODEBL groups to JDBC baseline groups for the Node lane.

| NODEBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| `CONN` | `JDBCBL-CONN` | Implemented (core DSN, TLS, handshake, and manager proxy connect paths) | `src/client.ts`; `src/dsn.ts`; `test/unit.test.js`; `test/integration.test.js` |
| `TXN` | `JDBCBL-TXN` | Implemented (explicit begin/commit/rollback/savepoint lifecycle, autocommit/session-schema APIs, invalid-state guards, and env-gated integration coverage for savepoint and implicit transaction flows) | `src/client.ts`; `src/protocol.ts`; `test/unit.test.js`; `test/integration.test.js` |
| `EXEC` | `JDBCBL-EXEC` | Implemented (simple/prepared/multi/batch/callable/generated-key execution paths, normalization error typing, stream paging, and env-gated integration coverage for streaming and multi-result surfaces) | `src/client.ts`; `src/sql.ts`; `test/unit.test.js`; `test/integration.test.js` |
| `META` | `JDBCBL-META` | Implemented (sys.* metadata routing now includes schema/table joins, restriction-aware filtering, JDBC-compatible alias shaping, recursive schema expansion/tree helpers, and env-gated metadata integration assertions) | `src/client.ts`; `src/metadata.ts`; `src/dsn.ts`; `test/unit.test.js`; `test/integration.test.js` |
| `TYPE` | `JDBCBL-TYPE` | Implemented (expanded type codec coverage includes explicit typed-OID encoding and broad decode parity across scalar, network, XML, text-search, geometry, range, composite, vector, and unknown fallback families with dedicated lane tests) | `src/types.ts`; `test/unit.test.js`; `test/types_parity.test.js`; `test/integration.test.js` |
| `ERR` | `JDBCBL-ERR` | Implemented (typed error classes and SQLSTATE mapping are covered, normalization failures map to `ScratchbirdSyntaxError` (`07001`), and protocol error translation now has dedicated tests for typed-class selection, `DETAIL/HINT` message shaping, empty-message fallback, and parser-failure fallback behavior) | `src/errors.ts`; `src/client.ts`; `test/unit.test.js`; `test/error_parity.test.js`; `test/integration.test.js` |
| `RES` | `JDBCBL-RES` | Implemented (resource lifecycle, pooling, cancellation, and resilience primitives are present with deterministic circuit-breaker/keepalive/leak-detection/telemetry unit coverage) | `src/client.ts`; `src/circuit_breaker.ts`; `src/keepalive.ts`; `src/leak_detector.ts`; `src/telemetry.ts`; `test/unit.test.js`; `test/integration.test.js` |
