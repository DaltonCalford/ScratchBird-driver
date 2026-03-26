# Baseline Requirement Mapping (PYTHONBL -> JDBC Baseline)

Scope: `tracks/p3/drivers/python` lane only.

Status legend:
- `Implemented`: baseline behavior is present and anchored by lane source/tests.
- `Partial`: baseline behavior exists but has explicit scope limits or incomplete validation coverage.
- `Missing`: no lane implementation evidence found.

## MGA Recovery Contract

- This lane follows ScratchBird's MGA/state-based engine recovery model.
- Reconnect or reopen only repairs transport and session state.
- Reconnect never resurrects abandoned in-flight transactions or replay lost statements.
- Transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth.
- Result resume is valid only for explicit suspended protocol states.
- `prepare_transaction(...)`, `commit_prepared(...)`, and
  `rollback_prepared(...)` now expose explicit prepared / limbo control
  surfaces through canonical transaction-control SQL.
- `supports_dormant_reattach()` is explicit and true on the native public
  lane; `detach_to_dormant()` returns the engine-issued `dormant_id` plus
  `dormant_reattach_token`, and `reattach_dormant(...)` uses those explicit
  startup parameters instead of implying reconnect-based recovery.
- `begin(...)` exposes the canonical MGA begin payload fields for
  `isolation_level`, `access_mode`, `deferrable`, `wait`, `timeout_ms`,
  `autocommit_mode`, `conflict_action`, and `read_committed_mode`.
- native `READY` status is authoritative for transaction activity, and the
  engine-endpoint lane can legitimately report an active session boundary
  while `txn_id == 0` across connect, commit, and rollback.
- native `TXN_STATUS` plus `current_txn_id` updates are also consumed as
  transaction-state surfaces, so the Python lane does not lose the fresh MGA
  session boundary when the engine republishes it after commit/rollback.
- `autocommit` mode transitions are local driver policy on the native lane;
  the Python wrapper does not push a synthetic wire `SET_OPTION autocommit`
  or client-side `BEGIN` against the server-owned session boundary.
- `canonical_isolation_label(...)` makes the current alias mapping explicit in
  lane source: `READ UNCOMMITTED` remains a legacy compatibility alias,
  `READ COMMITTED` => canonical `READ COMMITTED`,
  `REPEATABLE READ` => canonical `SNAPSHOT`,
  `SERIALIZABLE` => canonical `SNAPSHOT TABLE STABILITY`.
- `canonical_read_committed_mode_label(...)` plus the exported
  `READ_COMMITTED_MODE_*` constants make the canonical `READ COMMITTED`
  sub-modes explicit in lane source, including
  `READ COMMITTED READ CONSISTENCY`.
- `retry_scope_for_sqlstate(...)` makes the retry boundary explicit:
  `40001`/`40P01` => fresh statement only, `08xxx` => reconnect or reopen
  only, everything else => no automatic replay.
- internal result paging now enables portal resume only after
  `PORTAL_SUSPENDED`, and `_resume_suspended_portal(...)` rejects unsuspended
  resume with `55000`.
- See `../../../../docs/audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md`.

| PYTHONBL group | JDBC baseline group | Current status | Evidence anchors (lane source/tests) | Notes |
| --- | --- | --- | --- | --- |
| `CONN` | `JDBCBL-CONN` | `Implemented` | `src/scratchbird/dsn.py`; `src/scratchbird/connection.py`; `tests/test_connection_auth_protocol.py`; `tests/test_runtime_contract_gate.py` | Connection parity covers DSN alias normalization (including non-native protocol hints), TLS + plaintext (`sslmode=disable`) modes, manager-proxy fail-fast validation, startup/auth wiring, runtime session-schema APIs, liveness probing (`ping`/`is_valid`), and startup feature negotiation for `binary_transfer` + `compression` modes with deterministic runtime gate coverage. |
| `TXN` | `JDBCBL-TXN` | `Implemented` | `src/scratchbird/connection.py`; `src/scratchbird/protocol.py`; `tests/test_txn_exec_parity.py`; `tests/test_runtime_contract_gate.py`; `tests/test_integration.py` | TXN lifecycle parity includes begin/commit/rollback/savepoints, explicit prepared / limbo control helpers (`prepare_transaction`, `commit_prepared`, `rollback_prepared`), nested-begin and invalid-state guards, explicit begin-option payload support (`conflict_action`, `isolation_level`, `read_committed_mode`, `access_mode`, `deferrable`, `wait`, `timeout_ms`, `autocommit_mode`), explicit source-visible alias mapping via `canonical_isolation_label(...)` / `canonical_read_committed_mode_label(...)`, native `READY`/`TXN_STATUS`/`current_txn_id` transaction-state handling when the fresh session boundary stays active with `txn_id == 0`, native autocommit transitions that stay local to the wrapper instead of sending `SET_OPTION autocommit`, and deterministic plus live runtime transaction/savepoint flows. |
| `EXEC` | `JDBCBL-EXEC` | `Implemented` | `src/scratchbird/cursor.py`; `src/scratchbird/connection.py`; `src/scratchbird/sql.py`; `tests/test_txn_exec_parity.py`; `tests/test_sql.py`; `tests/test_runtime_contract_gate.py` | EXEC parity includes simple/extended execution, callable normalization/execution, multi-result traversal (`nextset`), batch/multi summary surfaces, generated-key propagation and retrieval, `native_sql`/`native_callable_sql`, and deterministic always-on runtime multi-result coverage. |
| `META` | `JDBCBL-META` | `Implemented` | `src/scratchbird/metadata.py`; `src/scratchbird/connection.py`; `tests/test_metadata_execution.py`; `tests/test_metadata_recursive_schema.py`; `tests/test_runtime_contract_gate.py` | Metadata parity includes executable collection routing, extended wrapper families, alias/query normalization, restriction-aware filtering (`%`/`_` with escape and null matching), recursive schema navigation payload shaping, and deterministic always-on runtime metadata wrapper coverage. |
| `TYPE` | `JDBCBL-TYPE` | `Implemented` | `src/scratchbird/types.py`; `tests/test_types.py`; `tests/test_runtime_contract_gate.py` | Type parity includes broad scalar/temporal/json/range/composite/vector coverage, typed array inference/decode, BYTEA escape/hex decode, wrapper-equivalent families (`Blob`/`Clob`/`RowId`/`Ref`/`SqlXml`), TIMETZ + temporal-family validation semantics, unknown fallback parity, and deterministic always-on runtime decode assertions. |
| `ERR` | `JDBCBL-ERR` | `Implemented` | `src/scratchbird/errors.py`, `src/scratchbird/connection.py:1113`, `src/scratchbird/connection.py:1307`, `tests/test_error_parity.py` | DB-API error hierarchy, SQLSTATE-to-error-class mapping, retry-boundary classification (`statement` vs `reconnect` vs `none`), protocol error message shaping (`SQLSTATE`/`DETAIL`/`HINT`), and parser-failure fallback behavior are covered by dedicated lane tests. |
| `RES` | `JDBCBL-RES` | `Implemented` | `src/scratchbird/connection.py:353`, `src/scratchbird/connection.py:564`, `src/scratchbird/connection.py:607`, `src/scratchbird/connection.py:1152`, `src/scratchbird/pool.py:46`, `src/scratchbird/pool.py:129`, `src/scratchbird/pool.py:192`, `src/scratchbird/pool.py:222`, `src/scratchbird/circuit_breaker.py`, `src/scratchbird/keepalive.py`, `src/scratchbird/leak_detection.py`, `src/scratchbird/telemetry.py`, `tests/test_resource_resilience.py`, `tests/test_integration.py:62`, `tests/test_txn_exec_parity.py` | Resource lifecycle plus pool/cache/retry/resilience primitives are now covered by deterministic lane tests (pool checkout/reuse/stale-replacement, statement cache, retry backoff, circuit-breaker transitions, keepalive validation, leak-detection guard behavior, telemetry metrics/slow-query tracking, explicit dormant detach/reattach token flow on the native public lane, and suspended-only portal-resume enforcement). |
