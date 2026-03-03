# S2 TXN/EXEC Implementation (DLB-MOJO-003)

Date: 2026-03-03
Lane: `tracks/alpha/drivers/mojo`

## Changes

1. Implemented lane-local TXN begin option mapping in `src/scratchbird.mojo`:
   - `begin(**kwargs)` now maps `isolation_level`, `access_mode`, `deferrable`, `wait|wait_mode`, `timeout_ms`, `autocommit_mode`, and `conflict_action` into `build_txn_begin_payload`.
   - Added TXN flag constants used by that mapping (`TXN_FLAG_HAS_*`).
2. Hardened TXN commit/rollback behavior:
   - `commit()` and `rollback()` now no-op when `_txn_id == 0` to avoid unnecessary wire calls outside an active transaction.
   - `_drain_until_ready()` now routes protocol `ERROR` payloads through `_raise_error()` for structured error propagation.
3. Implemented a minimal EXEC parity fix:
   - `query(sql, params)` now treats `params is not None` as the extended-query path, so explicit empty param lists (`[]`) no longer fall back to simple query mode.
4. Added targeted lane tests:
   - New `tests/txn_exec_parity.mojo` covers TXN begin payload mapping, TXN commit/rollback active-vs-inactive behavior, and EXEC simple-vs-extended path selection.
5. Updated TXN/EXEC rows in `BASELINE_REQUIREMENT_MAPPING.md` with current source/test anchors and gaps.

## Tests Run

1. `mojo tests/txn_exec_parity.mojo`
   - Result: FAIL (`mojo: command not found`)
2. `mojo tests/integration.mojo`
   - Result: FAIL (`mojo: command not found`)
3. `tests/sbdriver-conformance`
   - Result: FAIL (`mojo: command not found`)

## TXN Status

Recommendation: `PARTIAL`

Rationale:
- Begin payload/flag mapping and local transaction guardrails are now implemented with lane-local test coverage.
- Remaining gaps include nested-transaction guarding (`begin()` when `_txn_id != 0`), savepoint lifecycle APIs, and live transaction integration verification.

## EXEC Status

Recommendation: `PARTIAL`

Rationale:
- Execution path selection is now deterministic for explicit parameterized calls, including empty param lists.
- Remaining gaps include unavailable live test execution in this environment (`mojo` toolchain missing), plus broader parity work (stream/cancel integration assertions and full conformance enablement for `prepare_bind`/`cancel` by default).

## Remaining Gaps

1. Install/enable Mojo CLI in CI/local runner so lane tests can execute and report runtime pass/fail.
2. Add nested `begin()` guardrail behavior and tests for already-active transaction state.
3. Add live TXN lifecycle integration tests (begin, commit, rollback, and error paths) against a running ScratchBird endpoint.
4. Expand EXEC parity coverage for stream boundary/cancel behavior with runtime assertions.
