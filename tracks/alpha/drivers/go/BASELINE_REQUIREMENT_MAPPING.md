# Go Baseline Requirement Mapping (S0)

Scope: `tracks/alpha/drivers/go` lane only.

Status legend:
- `Implemented`: group coverage exists with lane source and lane test evidence.
- `Partial`: some baseline coverage exists, but one or more required JDBC-equivalent behaviors are missing or unproven.
- `Missing`: no lane implementation evidence found.

| GOBL group | JDBC baseline group(s) | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| `CONN` | `JDBCBL-CONN`, `JDBCBL-CFG` | `Partial` | `config.go:48`, `config.go:67`, `config.go:161`, `conn.go:77`, `conn.go:191`, `conn.go:211`, `conn.go:364`, `conn.go:486`, `protocol.go:267`, `protocol.go:336`, `config_test.go:12`, `config_test.go:60`, `conn_protocol_test.go:39`, `conn_protocol_test.go:60`, `conn_protocol_test.go:78`, `conn_protocol_test.go:100`, `conn_protocol_test.go:113`, `conn_protocol_test.go:124` |
| `TXN` | `JDBCBL-TXN` | `Partial` | `conn.go:667`, `conn.go:685`, `conn.go:697`, `conn.go:1798`, `conn.go:1802`, `conn.go:1813`, `protocol.go:547`, `protocol.go:572`, `txn_exec_test.go:20`, `txn_exec_test.go:36` (unsupported isolation now rejected; savepoint payload helpers exist, but no savepoint API is surfaced in `Conn`/`Tx`) |
| `EXEC` | `JDBCBL-EXEC` | `Partial` | `conn.go:707`, `conn.go:720`, `conn.go:732`, `conn.go:773`, `conn.go:797`, `rows.go:136`, `query.go:21`, `query.go:64`, `result.go:18`, `txn_exec_test.go:105`, `txn_exec_test.go:178`, `integration_test.go:50`, `integration_test.go:77` (exec paths now force `maxRows=0`; no `Rows.NextResultSet` surface in `rows.go`) |
| `META` | `JDBCBL-META` | `Partial` | `metadata.go:12`, `metadata.go:22` (metadata SQL helpers exist), `conformance/harness.go:156` (current conformance kinds cover auth/query/prepare/cancel only, not recursive metadata tree behavior) |
| `TYPE` | `JDBCBL-TYPE` | `Partial` | `types.go:80`, `types.go:152`, `types.go:314`, `types.go:476`, `types.go:853`, `rows.go:154`, `integration_test.go:64` |
| `ERR` | `JDBCBL-ERR` | `Partial` | `errors.go:12`, `errors.go:51`, `conn.go:1643`, `integration_test.go:77`, `conformance/harness.go:169`, `conformance/harness.go:395` |
| `RES` | `JDBCBL-RES` | `Partial` | `conn.go:127`, `conn.go:161`, `conn.go:1231`, `keepalive.go:64`, `leak_detector.go:42`, `circuit_breaker.go:58`, `telemetry.go:143`, `conformance/harness.go:431` |
