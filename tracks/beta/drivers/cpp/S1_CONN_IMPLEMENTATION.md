# DLB-CPP-002 S1 CONN Implementation

Date: 2026-03-03
Lane: `tracks/beta/drivers/cpp`

## What Changed

1. Updated connection transport resolution in `src/network_client.cpp`:
   - Enforced IP-only transport policy for this lane (`inet_listener` and `managed`).
   - `transport_mode=local_ipc`, `transport_mode=embedded`, and IPC-specific settings now fail fast before dial.
2. Added connect-time preflight checks in `src/network_client.cpp`:
   - `manager_proxy` mode now fails fast when `manager_auth_token` is missing.
   - Invalid `auth_method_id` values now fail fast unless they use the `scratchbird.auth.` namespace.
3. Expanded connection/auth/protocol coverage in `tests/test_driver_connectivity.cpp`:
   - Unskipped and exercised the direct local listener handshake smoke test.
   - Added a password-auth handshake test that validates startup/auth parameter wiring and AuthResponse payload.
   - Added deterministic IPC transport rejection coverage.
   - Added fail-fast tests for invalid auth method namespace and missing manager token.
4. Updated CONN mapping evidence in `BASELINE_REQUIREMENT_MAPPING.md`.

## Targeted Tests Run

1. `cmake --build /home/dcalford/CliWork/ScratchBird-driver/tracks/beta/drivers/cpp/build_odbc_gate --target scratchbird_client_tests -j8`
   - Result: `PASS`
2. `/home/dcalford/CliWork/ScratchBird-driver/tracks/beta/drivers/cpp/build_odbc_gate/scratchbird_client_tests --gtest_filter='DriverConnectivitySmokeTest.*'`
   - Result: `PASS` (`5 tests`)
3. `/home/dcalford/CliWork/ScratchBird-driver/tracks/beta/drivers/cpp/build_odbc_gate/scratchbird_client_tests --gtest_filter='DriverDefaultsEnvTest.*'`
   - Result: `PASS` (`7 tests`)

## CONN Status Recommendation

Recommendation: `PARTIAL`

## Remaining Concrete Gaps

1. Lane-local transport policy intentionally excludes driver-side IPC/embedded paths; those responsibilities remain in the ScratchBird server/engine project.
2. Lane tests still lack deterministic manager-proxy end-to-end handshake/auth coverage (success and failure matrices).
