# Node Baseline Requirement Mapping

Mapping of NODEBL groups to JDBC baseline groups for the Node lane.

| NODEBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| `CONN` | `JDBCBL-CONN` | Implemented (core DSN, TLS, handshake, and manager proxy connect paths) | `src/client.ts`; `src/dsn.ts`; `test/unit.test.js`; `test/integration.test.js` |
| `TXN` | `JDBCBL-TXN` | Partial (begin/commit/rollback/savepoint guards are covered and explicit autocommit/session-schema APIs are now present; broader live parity depth is still open) | `src/client.ts`; `src/protocol.ts`; `test/unit.test.js` |
| `EXEC` | `JDBCBL-EXEC` | Partial (simple/prepared execution plus batch, multi-result, generated-key, and callable API paths are implemented and unit-tested; deeper live integration coverage remains open) | `src/client.ts`; `src/sql.ts`; `test/unit.test.js`; `test/integration.test.js` |
| `META` | `JDBCBL-META` | Partial (metadata collection routing now includes catalog/key/privilege/type families with recursive schema shaping; richer DDL-editor payload depth remains open) | `src/client.ts`; `src/metadata.ts`; `src/dsn.ts`; `test/unit.test.js` |
| `TYPE` | `JDBCBL-TYPE` | Partial (broad codec/type support in source, lane tests still cover only a focused subset) | `src/types.ts`; `test/unit.test.js`; `test/integration.test.js` |
| `ERR` | `JDBCBL-ERR` | Partial (typed error classes and SQLSTATE mapping implemented with explicit mapping tests; broader failure-mode integration coverage remains open) | `src/errors.ts`; `src/client.ts`; `test/unit.test.js`; `test/integration.test.js` |
| `RES` | `JDBCBL-RES` | Partial (resource lifecycle, pooling, cancellation, and resilience primitives are present with added pool lifecycle unit coverage; stress-depth remains open) | `src/client.ts`; `src/circuit_breaker.ts`; `src/keepalive.ts`; `src/leak_detector.ts`; `test/unit.test.js`; `test/integration.test.js` |
