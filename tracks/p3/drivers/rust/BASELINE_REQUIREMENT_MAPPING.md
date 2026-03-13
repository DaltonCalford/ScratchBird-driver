# Baseline Requirement Mapping (RUSTBL -> JDBC Baseline)

Last updated: 2026-03-06

| RUSTBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| CONN | JDBCBL-CONN | Implemented | `src/config.rs`, `src/client.rs`, `src/protocol.rs`, `tests/config_test.rs`, `tests/runtime_contract_gate_test.rs` (protocol/SSL/compression normalization parity, `binary_transfer=false` + `compression=zstd` compatibility, deterministic manager-proxy MCP handshake success/failure, deterministic password/SCRAM and extended auth-method runtime coverage). |
| TXN | JDBCBL-TXN | Implemented | `src/client.rs`, `src/protocol.rs`, `tests/runtime_contract_gate_test.rs` (begin/commit/rollback/savepoint lifecycle plus first-class autocommit transition semantics with deterministic wire-event assertions). |
| EXEC | JDBCBL-EXEC | Implemented | `src/client.rs`, `src/sql.rs`, `tests/sql_test.rs`, `tests/integration_test.rs`, `tests/runtime_contract_gate_test.rs` (callable normalization/dispatch, multi-result summaries, batch/generated-key APIs, and deterministic runtime multi-result coverage). |
| META | JDBCBL-META | Implemented | `src/metadata.rs`, `src/client.rs`, `tests/metadata_test.rs`, `tests/runtime_contract_gate_test.rs` (collection alias/query resolver families, restriction-aware filtering, schema/get-tree/DDL payload helpers, and deterministic metadata matrix/runtime payload coverage). |
| TYPE | JDBCBL-TYPE | Implemented | `src/types.rs`, `tests/types_test.rs`, `tests/integration_test.rs` (scalar/advanced type coverage remains implemented with lane tests). |
| ERR | JDBCBL-ERR | Implemented | `src/errors.rs`, `src/protocol.rs`, `src/client.rs`, `tests` (spec-complete SQLSTATE mapping and protocol error translation). |
| RES | JDBCBL-RES | Implemented | `src/client.rs`, `src/pool.rs`, `src/keepalive.rs`, `src/circuit_breaker.rs`, `tests` (connection lifecycle, pooling/resilience primitives, and cleanup semantics remain implemented). |

## Notes on status

- `Implemented`: lane code has working path(s) plus direct source/test evidence.
- `Partial`: lane code has baseline path(s), but coverage depth or validation breadth is limited.
- `Gap`: baseline surface is not yet exposed as callable driver behavior in this lane.

