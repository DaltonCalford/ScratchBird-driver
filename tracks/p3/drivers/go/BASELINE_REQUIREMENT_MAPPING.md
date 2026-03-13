# Go Baseline Requirement Mapping (S0)

Scope: `tracks/p3/drivers/go` lane only.

Status legend:
- `Implemented`: baseline-complete coverage exists with lane source and lane test evidence.
- `Partial`: some baseline coverage exists, but one or more required JDBC-equivalent behaviors are missing or unproven.
- `Missing`: no lane implementation evidence found.

| GOBL group | JDBC baseline group(s) | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| `CONN` | `JDBCBL-CONN`, `JDBCBL-CFG` | `Implemented` | `config.go`, `conn.go`, `protocol.go`, `config_test.go`, `conn_protocol_test.go`, `runtime_contract_gate_test.go` (protocol/SSL/compression normalization parity, `binary_transfer=false` compatibility, manager-proxy token guard, auth-plugin startup parameter wiring, broader auth-method response handling, and always-on runtime gate manager-proxy handshake coverage). |
| `TXN` | `JDBCBL-TXN` | `Implemented` | `conn.go`, `protocol.go`, `txn_exec_test.go`, `runtime_contract_gate_test.go` (begin/commit/rollback plus savepoint/release/rollback-to APIs with wire validation and runtime gate transaction lifecycle coverage). |
| `EXEC` | `JDBCBL-EXEC` | `Implemented` | `conn.go`, `rows.go`, `rows_next_result_test.go`, `exec_surfaces.go`, `exec_surfaces_test.go`, `query_test.go`, `runtime_contract_gate_test.go` (simple/extended execution paths, multi-result traversal and summaries, callable/batch/generated-key APIs, and runtime gate multi-result execution coverage). |
| `META` | `JDBCBL-META` | `Implemented` | `metadata.go`, `metadata_rows.go`, `conn.go`, `metadata_test.go`, `config_test.go`, `runtime_contract_gate_test.go` (metadata collection resolver aliases, restriction-aware filtering semantics, schema expansion toggles, and runtime gate metadata query coverage). |
| `TYPE` | `JDBCBL-TYPE` | `Implemented` | `types.go`, `rows.go`, `types_test.go`, `runtime_contract_gate_test.go` (expanded OID encode/decode coverage including `timetz` and geometry families, OID metadata helper parity, and runtime gate binary decode coverage). |
| `ERR` | `JDBCBL-ERR` | `Implemented` | `errors.go`, `errors_test.go`, `errors_protocol_test.go`, `conn.go`, `conformance/harness.go` (SQLSTATE-to-kind mapping and protocol error translation with detail/hint propagation and truncation guards). |
| `RES` | `JDBCBL-RES` | `Implemented` | `conn.go`, `keepalive.go`, `leak_detector.go`, `circuit_breaker.go`, `telemetry.go`, `resilience_test.go` (connection lifecycle cleanup, keepalive/leak/circuit-breaker/telemetry resource guards with deterministic lane tests). |

