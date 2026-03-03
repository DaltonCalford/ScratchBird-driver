# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope

- Lane-local S0 artifact only for `tracks/alpha/drivers/mojo`.
- Evidence is restricted to files in this lane; no cross-lane claims are made.

## CONN (JDBCBL)

- Current status: Implemented
- Lane-local source anchors:
- `src/scratchbird.mojo:497` (`ScratchBirdConfig` DSN/config handling)
- `src/scratchbird.mojo:1244` (`ScratchBirdConnection` construction and connection bootstrap)
- `src/scratchbird.mojo:1264` (`_connect` TLS socket setup and connect-time validation)
- `src/scratchbird.mojo:1304` (`_startup_and_auth` startup/auth exchange)
- `src/scratchbird.mojo:1390` (`_perform_manager_connect` manager-proxy connect path)
- `src/scratchbird.mojo:1641` (`ping`)
- `src/scratchbird.mojo:1481` (`close`)
- Lane-local test anchors:
- `tests/integration.mojo:19`
- `tests/sbdriver_conformance.mojo:157`
- Gaps/next actions:
- Add lane tests that exercise `front_door_mode=manager_proxy` and auth failure paths.
- Add lane tests for rejected connect modes (`sslmode=disable`, `binary_transfer=false`, `compression=zstd`).

## TXN (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:1019` (`build_txn_begin_payload`)
- `src/scratchbird.mojo:1025` (`build_txn_commit_payload`)
- `src/scratchbird.mojo:1029` (`build_txn_rollback_payload`)
- `src/scratchbird.mojo:1635` (`begin` kwargs->flags/payload mapping)
- `src/scratchbird.mojo:1671` (`commit` no-op when no active txn)
- `src/scratchbird.mojo:1678` (`rollback` no-op when no active txn)
- `src/scratchbird.mojo:1703` (`_drain_until_ready` propagates protocol error details)
- Lane-local test anchors:
- `tests/txn_exec_parity.mojo:55` (`begin` flag/payload mapping assertions)
- `tests/txn_exec_parity.mojo:90` (inactive transaction commit/rollback no-op assertions)
- `tests/txn_exec_parity.mojo:98` (active transaction commit/rollback message assertions)
- Gaps/next actions:
- Add guardrails for nested `begin()` calls when `_txn_id` is already active.
- Add live transaction integration coverage against a running ScratchBird endpoint.

## EXEC (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:1526` (`query` path selection for `params is None` vs parameterized execution)
- `src/scratchbird.mojo:1545` (`_extended_query` parse/bind/execute flow)
- `src/scratchbird.mojo:1584` (`_fetch_more`)
- `src/scratchbird.mojo:1590` (`_read_resultset`)
- `src/scratchbird.mojo:1542` (`stream`)
- `src/scratchbird.mojo:751` (`ScratchBirdStream`)
- `src/scratchbird.mojo:1632` (`prepare`)
- `src/scratchbird.mojo:810` (`ScratchBirdStatement.execute`)
- `src/scratchbird.mojo:1699` (`cancel`)
- Lane-local test anchors:
- `tests/txn_exec_parity.mojo:108` (`query(..., None)` simple-query path assertion)
- `tests/txn_exec_parity.mojo:117` (`query(..., [])` extended-query path assertion)
- `tests/integration.mojo:22`
- `tests/sbdriver_conformance.mojo:161`
- `tests/sbdriver_conformance.mojo:174`
- `tests/sbdriver_conformance.mojo:190`
- `tests/README.md:10`
- Gaps/next actions:
- Conformance scaffold still defaults `prepare_bind` and `cancel` to skipped unless opt-in env flags are set.
- Add lane assertions for streamed fetch boundaries and cancel behavior against long-running statements.

## META (JDBCBL)

- Current status: Planned
- Lane-local source anchors:
- `src/scratchbird.mojo:737` (`ScratchBirdColumn` row-description metadata shape)
- `src/scratchbird.mojo:1173` (`parse_row_description`)
- `src/scratchbird.mojo:1575` (`_read_resultset` fills result-set column metadata)
- `src/scratchbird.mojo:1668` (metadata SQL constants for `sys.schemas`, `sys.tables`, `sys.columns`, indexes, constraints, routines)
- Lane-local test anchors:
- No metadata helper tests found in `tests/`.
- Gaps/next actions:
- Add callable metadata helper APIs that use the `METADATA_*_QUERY` constants.
- Add lane tests for schema/table/column metadata results and stability.

## TYPE (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:24` (OID constants used by type codec paths)
- `src/scratchbird.mojo:300` (`decode_value`)
- `src/scratchbird.mojo:368` (`encode_value`)
- `src/scratchbird.mojo:244` (`_parse_array_literal`)
- `src/scratchbird.mojo:262` (`_parse_vector_literal`)
- `src/scratchbird.mojo:279` (`_parse_range_literal`)
- Lane-local test anchors:
- `tests/integration.mojo:26`
- `tests/sbdriver_conformance.mojo:182`
- Gaps/next actions:
- Add lane tests with per-type value assertions for both decode and encode paths.
- Add lane tests for null/array/range/vector edge cases and unsupported OID fallback behavior.

## ERR (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:139` (`ScratchBirdError` with `sqlstate`, `detail`, `hint`)
- `src/scratchbird.mojo:1127` (`parse_error_message`)
- `src/scratchbird.mojo:1612` (`_raise_error`)
- `src/scratchbird.mojo:1511` (`query` wraps operation and propagates failures)
- `src/scratchbird.mojo:1559` (explicit `ScratchBirdError("parameter count mismatch", "07001")`)
- Lane-local test anchors:
- `tests/sbdriver_conformance.mojo:171`
- `tests/sbdriver_conformance.mojo:188`
- `tests/sbdriver_conformance.mojo:209`
- Gaps/next actions:
- Add lane tests asserting propagated `sqlstate/detail/hint` content, not just exception string presence.
- Add negative tests for protocol/message truncation error paths.

## RES (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:1481` (`ScratchBirdConnection.close`)
- `src/scratchbird.mojo:781` (`ScratchBirdStream.close`)
- `src/scratchbird.mojo:1492` (`_begin_operation` circuit-breaker/keepalive/telemetry hooks)
- `src/scratchbird/leak_detector.mojo:56` (`LeakDetector` and guard-based checkin)
- `src/scratchbird/circuit_breaker.mojo:31` (`CircuitBreaker` state transitions)
- `src/scratchbird/keepalive.mojo:24` (`KeepaliveTracker`)
- `src/scratchbird/telemetry.mojo:145` (`TelemetryCollector`)
- `src/scratchbird/pipeline.mojo:36` (`QueryPipeline` scaffold)
- Lane-local test anchors:
- `tests/integration.mojo:31`
- `tests/sbdriver_conformance.mojo:212`
- Gaps/next actions:
- Add lane tests that verify idempotent close/release behavior for connection and stream objects.
- Complete or remove placeholder lifecycle paths (`pass` markers in keepalive/telemetry/pipeline scaffolds) to reduce ambiguity.
