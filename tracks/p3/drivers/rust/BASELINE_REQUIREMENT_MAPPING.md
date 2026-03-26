# Baseline Requirement Mapping (RUSTBL -> JDBC Baseline)

Last updated: 2026-03-06

## MGA Recovery Contract

- This lane follows ScratchBird's MGA/state-based engine recovery model.
- Reconnect or reopen only repairs transport and session state.
- Reconnect never resurrects abandoned in-flight transactions or replay lost statements.
- Transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth.
- Result resume is valid only for explicit suspended protocol states.
- `Client::prepare_transaction(...)`, `commit_prepared(...)`, and
  `rollback_prepared(...)` expose prepared/limbo control SQL explicitly in
  lane source.
- `supports_dormant_reattach()` is explicit and `detach_to_dormant(...)` /
  `reattach_dormant(...)` fail closed with `0A000` instead of implying that
  reconnect can recover dormant work.
- `TxnBeginOptions` exposes the canonical MGA begin flags for
  `isolation_level`, `access_mode`, `deferrable`, `wait`, `timeout_ms`,
  `autocommit_mode`, `conflict_action`, and `read_committed_mode`.
- Current isolation alias mapping is explicit in lane source:
  `READ COMMITTED` => canonical `READ COMMITTED`,
  `REPEATABLE READ` => canonical `SNAPSHOT`,
  `SERIALIZABLE` => canonical `SNAPSHOT TABLE STABILITY`.
- `READ_COMMITTED_MODE_*` plus `canonical_read_committed_mode_label(...)`
  make the canonical `READ COMMITTED` sub-modes explicit in lane source,
  including the direct `READ COMMITTED READ CONSISTENCY` selector.
- `retry_scope_for_sqlstate(...)` makes the retry boundary explicit:
  `40001`/`40P01` => statement only, `08xxx` => reconnect only, all other
  SQLSTATEs => no automatic replay.
- Native `READY` / `TXN_STATUS` frames now own transaction activity in lane
  source, so a fresh native MGA boundary can remain active while `txn_id == 0`.
- Compatible default `READ COMMITTED` `begin(...)` calls now adopt that
  already-active fresh native boundary, while unsupported non-default
  fresh-boundary begin requests fail closed with `0A000`.
- Native autocommit transitions now stay local to the wrapper instead of
  sending `SET_OPTION autocommit` against a server-owned fresh boundary.
- See `../../../../docs/audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md`.

| RUSTBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) |
| --- | --- | --- | --- |
| CONN | JDBCBL-CONN | Implemented | `src/config.rs`, `src/client.rs`, `src/protocol.rs`, `tests/config_test.rs`, `tests/runtime_contract_gate_test.rs` (protocol/SSL/compression normalization parity, `binary_transfer=false` + `compression=zstd` compatibility, deterministic manager-proxy MCP handshake success/failure, deterministic password/SCRAM and extended auth-method runtime coverage). |
| TXN | JDBCBL-TXN | Implemented | `src/client.rs`, `src/protocol.rs`, `tests/runtime_contract_gate_test.rs`, `tests/integration_test.rs` (begin/commit/rollback/savepoint lifecycle, canonical MGA begin-option payloads for isolation/read-committed-mode/access/deferrable/wait/timeout/autocommit/conflict-action, active-with-zero-`txn_id` fresh-boundary handling, explicit prepared/limbo control SQL helpers plus dormant fail-closed helpers, first-class autocommit transition semantics with deterministic wire-event assertions, and focused live connect/commit/rollback/nested-begin certification). |
| EXEC | JDBCBL-EXEC | Implemented | `src/client.rs`, `src/sql.rs`, `tests/sql_test.rs`, `tests/integration_test.rs`, `tests/runtime_contract_gate_test.rs` (callable normalization/dispatch, multi-result summaries, batch/generated-key APIs, explicit suspended-only portal-resume guards, and deterministic runtime multi-result coverage). |
| META | JDBCBL-META | Implemented | `src/metadata.rs`, `src/client.rs`, `tests/metadata_test.rs`, `tests/runtime_contract_gate_test.rs` (collection alias/query resolver families, restriction-aware filtering, schema/get-tree/DDL payload helpers, and deterministic metadata matrix/runtime payload coverage). |
| TYPE | JDBCBL-TYPE | Implemented | `src/types.rs`, `tests/types_test.rs`, `tests/integration_test.rs` (scalar/advanced type coverage remains implemented with lane tests). |
| ERR | JDBCBL-ERR | Implemented | `src/errors.rs`, `src/protocol.rs`, `src/client.rs`, `tests` (spec-complete SQLSTATE mapping, explicit retry-boundary helpers, and protocol error translation). |
| RES | JDBCBL-RES | Implemented | `src/client.rs`, `src/pool.rs`, `src/keepalive.rs`, `src/circuit_breaker.rs`, `tests` (connection lifecycle, pooling/resilience primitives, and cleanup semantics remain implemented). |

## Notes on status

- `Implemented`: lane code has working path(s) plus direct source/test evidence.
- `Partial`: lane code has baseline path(s), but coverage depth or validation breadth is limited.
- `Gap`: baseline surface is not yet exposed as callable driver behavior in this lane.
