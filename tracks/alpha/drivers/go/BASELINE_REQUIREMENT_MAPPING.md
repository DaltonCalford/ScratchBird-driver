# Go Baseline Requirement Mapping (S0)

Scope: `tracks/alpha/drivers/go` lane only.

Status legend:
- `Implemented`: group coverage exists with lane source and lane test evidence.
- `Partial`: some baseline coverage exists, but one or more required JDBC-equivalent behaviors are missing or unproven.
- `Missing`: no lane implementation evidence found.

| GOBL group | JDBC baseline group(s) | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| `CONN` | `JDBCBL-CONN`, `JDBCBL-CFG` | `Partial` | `config.go:48`, `config.go:67`, `config.go:161`, `conn.go:77`, `conn.go:191`, `conn.go:211`, `conn.go:364`, `conn.go:486`, `protocol.go:267`, `protocol.go:336`, `config_test.go:12`, `config_test.go:60`, `conn_protocol_test.go:39`, `conn_protocol_test.go:60`, `conn_protocol_test.go:78`, `conn_protocol_test.go:100`, `conn_protocol_test.go:113`, `conn_protocol_test.go:124` |
| `TXN` | `JDBCBL-TXN` | `Partial` | `conn.go`; `protocol.go`; `txn_exec_test.go` (explicit savepoint/release/rollback-to APIs now surfaced on `Conn`/`Tx` with wire tests and state/name guards; broader live transaction depth remains open) |
| `EXEC` | `JDBCBL-EXEC` | `Partial` | `conn.go:707`, `conn.go:720`, `conn.go:732`, `conn.go:773`, `conn.go:797`, `rows.go`, `rows_next_result_test.go`, `query.go:21`, `exec_surfaces.go`, `result.go:18`, `txn_exec_test.go:105`, `exec_surfaces_test.go`, `query_test.go`, `integration_test.go:50`, `integration_test.go:77` (exec paths force `maxRows=0`; `Rows` surfaces JDBC-style multi-result boundaries via `HasNextResultSet/NextResultSet`; first-class callable/batch/multi-summary/generated-key APIs are lane-tested; broader live advanced execution depth remains open) |
| `META` | `JDBCBL-META` | `Partial` | `metadata.go`; `metadata_rows.go`; `conn.go`; `metadata_test.go`; `config_test.go` (metadata collection normalization/query resolution plus first-class restriction-aware filtering are implemented via `Conn.QueryMetadataWithRestrictions`; alias-based key matching, null matching, and unknown restriction ignore behavior are lane-tested. Live metadata integration depth remains open) |
| `TYPE` | `JDBCBL-TYPE` | `Partial` | `types.go:80`, `types.go:152`, `types.go:314`, `types.go:476`, `types.go:853`, `rows.go:154`, `types_test.go`, `integration_test.go:64` (lane tests now cover representative scalar/advanced encode-decode behavior: json/jsonb, bytea, uuid, numeric/money, vector, range, composite, unknown-type heuristics, and OID/type helper mappings; full per-oid fidelity matrix and broader live depth remain open) |
| `ERR` | `JDBCBL-ERR` | `Implemented` | `errors.go`, `errors_test.go`, `errors_protocol_test.go`, `conn.go:1737`, `integration_test.go:77`, `conformance/harness.go:169`, `conformance/harness.go:395` (SQLSTATE-to-kind mapping plus wire protocol error translation (`buildProtocolError`) are lane-tested, including detail/hint propagation, unknown-state fallback, and truncated payload handling.) |
| `RES` | `JDBCBL-RES` | `Implemented` | `conn.go:127`, `conn.go:161`, `conn.go:1231`, `keepalive.go:64`, `leak_detector.go:42`, `circuit_breaker.go:58`, `telemetry.go:143`, `conformance/harness.go:431`, `resilience_test.go` (lane-local deterministic resilience lifecycle tests cover keepalive tracker/manager idle validation + timeout behavior, leak-detector checkout/guard stats paths, circuit-breaker state transitions/open-guard execution semantics, and telemetry metrics/slow-query capture/export snapshots.) |
