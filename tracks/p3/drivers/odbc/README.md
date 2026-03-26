# ScratchBird ODBC Driver (ODBC 3.8)

ODBC 3.8 driver for ScratchBird SBWP v1.1.

## Documentation

- [Getting started](../../../../docs/getting-started/odbc.md)
- [API reference](../../../../docs/api-reference/odbc.md)
- [Connectivity guide](../../../../docs/user-documentation/connectivity/odbc.md)
- [Baseline mapping](BASELINE_REQUIREMENT_MAPPING.md)

## MGA Recovery Contract

This lane follows ScratchBird's MGA/state-based engine recovery model.

- reconnect or reopen only repairs transport and session state
- reconnect never resurrects abandoned in-flight transactions or replay lost statements
- transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth
- result resume is valid only for explicit suspended protocol states
- disconnect clears statement handles, prepared SQL cache, transaction flags,
  and bridge session state before any later reconnect
- the focused live recovery closure test in
  `tests/test_odbc_external_runtime.cpp` now proves that rollback leaves the
  next query immediately usable on the reopened native MGA boundary with no
  reconnect and no statement replay
- `SQL_ATTR_TXN_ISOLATION` still exposes only ODBC's standard isolation flags;
  the lane now documents their canonical MGA meaning directly in source:
  `READ UNCOMMITTED` remains a legacy compatibility alias,
  `READ COMMITTED` => canonical `READ COMMITTED`,
  `REPEATABLE READ` and `VERSIONING` => canonical `SNAPSHOT`,
  `SERIALIZABLE` => canonical `SNAPSHOT TABLE STABILITY`
- a distinct public selector for `READ COMMITTED READ CONSISTENCY` is not yet
  exposed through the ODBC transaction attribute surface
- retry remains SQLSTATE-driven and fail-closed in this lane:
  `40001`/`40P01` require a fresh statement boundary,
  `08xxx` requires reconnect or reopen, and nothing auto-replays a whole
  transaction
- prepared / limbo truth is explicit in lane source through
  `supportsPreparedTransactions()` plus `buildPreparedTransactionSql(...)`
  rather than implied by reconnect behavior
- dormant reattach truth is explicit and fail-closed through
  `supportsDormantReattach()` and `rejectDormantReattach(...)`
- standalone portal resume is intentionally absent and source-visible through
  `supportsPortalResume() -> false`

See `../../../../docs/audit/MGA_RECONNECT_AND_TRANSACTION_RECOVERY_AUDIT.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build coverage. |
| Windows | Supported | CI build coverage. |
| macOS | Untested | Not currently covered in CI. |

## Build

```bash
cmake -S . -B build
cmake --build build --config Release
```

See `docs/BUILD_MATRIX.md` for required ODBC/OpenSSL dependencies.

## Connection Strings

Direct/native:

```ini
Driver={ScratchBird};Server=127.0.0.1;Port=3092;Database=mydb;UID=user;PWD=pass;SSLMode=prefer
```

Manager-proxy:

```ini
Driver={ScratchBird};Server=127.0.0.1;Port=3090;Database=mydb;UID=user;PWD=pass;FrontDoorMode=manager_proxy;ManagerAuthToken=token
```

## Baseline Mapping

See [BASELINE_REQUIREMENT_MAPPING.md](BASELINE_REQUIREMENT_MAPPING.md) for S0 ODBCBL-to-JDBC baseline status and evidence anchors.
