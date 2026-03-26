# ScratchBird Python Driver

ScratchBird DB-API 2.0 driver using the ScratchBird native wire protocol.

## Documentation

- [Getting started](../../../../docs/getting-started/python.md)
- [API reference](../../../../docs/api-reference/python.md)
- [Baseline requirement mapping](BASELINE_REQUIREMENT_MAPPING.md)

## MGA Recovery Contract

This lane follows ScratchBird's MGA/state-based engine recovery model.

- reconnect or reopen only repairs transport and session state
- reconnect never resurrects abandoned in-flight transactions or replay lost statements
- transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth
- result resume is valid only for explicit suspended protocol states
- `prepare_transaction(...)`, `commit_prepared(...)`, and
  `rollback_prepared(...)` now expose explicit prepared / limbo control
  surfaces through canonical transaction-control SQL
- `supports_dormant_reattach()` is explicit and true on the native public
  lane, `detach_to_dormant()` returns the engine-issued `dormant_id` plus
  `dormant_reattach_token`, and `reattach_dormant(...)` uses those explicit
  startup parameters on reconnect instead of implying reconnect-based recovery
- `begin(...)` exposes the canonical MGA begin payload fields for
  `isolation_level`, `access_mode`, `deferrable`, `wait`, `timeout_ms`,
  `autocommit_mode`, `conflict_action`, and `read_committed_mode`
- native `READY` status is authoritative for transaction activity, and the
  engine-endpoint lane can legitimately report an active session boundary
  while `txn_id == 0` across connect, commit, and rollback
- native `TXN_STATUS` plus `current_txn_id` updates are also consumed as
  transaction-state surfaces, so the Python lane does not lose the fresh MGA
  session boundary when the engine republishes it after commit/rollback
- `autocommit` mode transitions are local driver policy on the native lane;
  the Python wrapper does not push a synthetic wire `SET_OPTION autocommit`
  or client-side `BEGIN` against the server-owned session boundary
- `canonical_isolation_label(...)` makes the current alias mapping explicit in
  lane source: `READ UNCOMMITTED` remains a legacy compatibility alias,
  `READ COMMITTED` => canonical `READ COMMITTED`,
  `REPEATABLE READ` => canonical `SNAPSHOT`,
  `SERIALIZABLE` => canonical `SNAPSHOT TABLE STABILITY`
- `canonical_read_committed_mode_label(...)` plus the exported
  `READ_COMMITTED_MODE_*` constants make the canonical `READ COMMITTED`
  sub-modes explicit in lane source; `READ_COMMITTED_MODE_READ_CONSISTENCY`
  now selects canonical `READ COMMITTED READ CONSISTENCY`
- `retry_scope_for_sqlstate(...)` makes the retry boundary explicit:
  `40001`/`40P01` => fresh statement only, `08xxx` => reconnect or reopen
  only, everything else => no automatic replay
- internal result paging now enables portal resume only after
  `PORTAL_SUSPENDED`, and `_resume_suspended_portal(...)` rejects unsuspended
  resume with `55000`

See `../../../../docs/audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md`.

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Development

```bash
python -m pip install -e .
```

## Testing

Unit tests:

```bash
python -m pip install -e ".[test]"
pytest
```

Integration tests (requires a running server and a DSN):

```bash
export SCRATCHBIRD_TEST_DSN="scratchbird://user:pass@localhost:3092/mydb"
pytest python/tests/test_integration.py
```

## Packaging

Build a wheel/sdist:

```bash
python -m pip install build
python -m build
```

## Publish

```bash
python -m pip install twine
twine upload dist/*
```
