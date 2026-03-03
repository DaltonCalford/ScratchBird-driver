# Node Baseline Requirement Mapping

Mapping of NODEBL groups to JDBC baseline groups for the Node lane.

| NODEBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| `CONN` | `JDBCBL-CONN` | Implemented (core DSN, TLS, handshake, and manager proxy connect paths) | `src/client.ts:336-366`; `src/client.ts:678-829`; `src/client.ts:1299-1357`; `src/dsn.ts:37-186`; `test/unit.test.js:19-42`; `test/integration.test.js:23-31` |
| `TXN` | `JDBCBL-TXN` | Partial (begin/commit/rollback/savepoint paths now enforce deterministic transaction-state guards and have lane unit coverage; autocommit/session-schema parity is still incomplete) | `src/client.ts:417-504`; `src/client.ts:636-645`; `src/client.ts:943-957`; `src/client.ts:1186-1189`; `src/protocol.ts:513-561`; `test/unit.test.js:119-156` |
| `EXEC` | `JDBCBL-EXEC` | Partial (simple/prepared execution, bind alias normalization, streaming, cancel, and native SQL normalization are covered; batch/multi-result/generated-key/callable parity remains open) | `src/client.ts:369-403`; `src/client.ts:381-383`; `src/client.ts:986-1128`; `src/client.ts:1162-1164`; `src/sql.ts:13-111`; `test/unit.test.js:158-191`; `test/integration.test.js:23-69` |
| `META` | `JDBCBL-META` | Partial (metadata SQL catalog constants exported, no dedicated metadata API/test surface yet) | `src/metadata.ts:9-31`; `src/index.ts:64`; `src/client.ts:368-583` |
| `TYPE` | `JDBCBL-TYPE` | Partial (broad codec/type support in source, narrow test coverage in lane tests) | `src/types.ts:242-315`; `src/types.ts:318-431`; `src/types.ts:434-520`; `src/types.ts:816-985`; `test/unit.test.js:56-68`; `test/integration.test.js:45-50` |
| `ERR` | `JDBCBL-ERR` | Partial (typed error classes and SQLSTATE mapping implemented, minimal explicit error mapping tests) | `src/errors.ts:8-101`; `src/client.ts:342-347`; `src/client.ts:853-855`; `src/client.ts:1151-1157`; `test/integration.test.js:56-69` |
| `RES` | `JDBCBL-RES` | Partial (resource lifecycle, pooling, cancellation, and resilience primitives are present; coverage is limited) | `src/client.ts:595-622`; `src/client.ts:631-658`; `src/client.ts:1125-1142`; `src/client.ts:1163-1243`; `src/circuit_breaker.ts:25-134`; `src/keepalive.ts:35-104`; `src/leak_detector.ts:44-105`; `test/integration.test.js:56-73` |
