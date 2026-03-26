# ScratchBird C/C++ Client (`libscratchbird_client`)

Native C/C++ client library for ScratchBird SBWP v1.1.

## Lane Docs

- [Baseline Requirement Mapping (S0)](./BASELINE_REQUIREMENT_MAPPING.md)
- [Build Matrix](docs/BUILD_MATRIX.md)
- [Getting started](../../../../docs/getting-started/cpp.md)
- [API reference](../../../../docs/api-reference/cpp.md)

## MGA Recovery Contract

This lane follows ScratchBird's MGA/state-based engine recovery model.

- reconnect or reopen only repairs transport and session state
- reconnect never resurrects abandoned in-flight transactions or replay lost statements
- transaction recovery in the lane means reset, rollback, reopen, or retry against engine truth
- result resume is valid only for explicit suspended protocol states
- `sb_txn_options` exposes the canonical MGA begin payload fields directly, and
  `sb_canonical_isolation_name(...)` now makes the current isolation-byte
  meaning explicit in lane source: isolation byte `0` remains a legacy
  compatibility alias, `1` => canonical `READ COMMITTED`,
  `2` => canonical `SNAPSHOT`, `3` => canonical `SNAPSHOT TABLE STABILITY`
- `sb_txn_options.read_committed_mode` now exposes the distinct
  `READ COMMITTED READ CONSISTENCY` / record-version / no-record-version
  selector without changing the lane's compatibility isolation aliases
- `sb_retry_scope_for_sqlstate(...)` makes the retry boundary explicit:
  `40001`/`40P01` => fresh statement only, `08xxx` => reconnect or reopen
  only, everything else => no automatic replay
- native `READY` plus `current_txn_id` are authoritative for transaction
  activity in this lane; a fresh active session can legitimately report
  `txn_id == 0` across the public wire seam
- compatible default `beginTransaction(...)` calls now adopt that already
  active fresh native MGA boundary instead of sending a redundant `TXN_BEGIN`
- prepared / limbo truth is explicit in both public surfaces:
  `sb_tx_prepare_transaction(...)`, `sb_tx_commit_prepared(...)`,
  `sb_tx_rollback_prepared(...)`, plus
  `Connection::prepareTransaction(...)`, `Connection::commitPrepared(...)`,
  and `Connection::rollbackPrepared(...)` all emit canonical control SQL
- dormant truth is explicit and fail-closed:
  `sb_tx_detach_to_dormant(...)` / `sb_tx_reattach_dormant(...)` and
  `Connection::detachToDormant(...)` / `Connection::reattachDormant(...)`
  reject with not-supported until a public dormant-token flow exists
- standalone portal resume is intentionally absent and source-visible through
  `sb_supports_portal_resume() -> 0` and
  `Connection::supportsPortalResume() -> false`
- env-gated live recovery proof now exists in
  `tests/test_driver_connectivity.cpp`:
  `DriverRecoveryIntegrationTest.CppReconnectDoesNotResurrectAbandonedTransaction`
  and `DriverRecoveryIntegrationTest.CApiReconnectDoesNotReuseAbandonedTransactionState`
  run against `SCRATCHBIRD_TEST_DSN` and prove that disconnect/reconnect
  clears abandoned transaction and savepoint state rather than replaying it
- the shared native client fix is also exercised live through the CLI sample:
  `tracks/p3/drivers/cli/conformance/sbwp_conformance_manifest.sample.json`
  now proves that explicit `begin -> commit` and `begin -> rollback` flows
  keep the immediate next query usable on the same reopened native boundary

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

See `docs/BUILD_MATRIX.md` for toolchain prerequisites.

## Quick Start

```c
#include <scratchbird/client/scratchbird_client.h>

int main(void) {
    sb_error err = {0};
    sb_connection* conn =
        sb_connect("scratchbird://user:pass@127.0.0.1:3092/mydb", &err);
    if (!conn) {
        return 1;
    }

    sb_result* result = sb_query(conn, "SELECT 1", &err);
    if (result) {
        sb_result_free(result);
    }
    sb_disconnect(conn);
    return 0;
}
```

Direct and manager-proxy listener modes are supported. The lane remains
listener/IP-bound and does not implement driver-side IPC transport.

The public C++ surface now also includes:

- parsed `ConnectionConfig` mirroring listener-bound role/schema/app/TLS and
  compression settings
- `PreparedStatement` with typed parameter setters and execute helpers
- `ConnectionPool` and `ConnectionLease` RAII wrappers over the pooled C API
