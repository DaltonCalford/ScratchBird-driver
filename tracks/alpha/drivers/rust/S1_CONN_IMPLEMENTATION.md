# DLB-RUST-002 S1 CONN Implementation

Date: 2026-03-03
Lane: `tracks/alpha/drivers/rust`

## What Changed

1. Added connection preflight validation in `src/client.rs`:
   - `preflight_connect()` now normalizes protocol/front-door mode and validates required connect settings before any socket dial.
   - Added fail-fast manager proxy guard: `manager_proxy` now requires `manager_auth_token` before transport connect.
2. Added startup auth plugin selection wiring in `src/client.rs`:
   - `build_startup_params()` now composes startup params and applies `auth_method_id`, `auth_payload_json`, `auth_payload_b64`, and `auth_provider_profile` via `protocol::apply_auth_plugin_selection`.
   - `handshake()` now accepts prebuilt startup params from preflight.
3. Expanded lane CONN tests:
   - `src/client.rs` unit tests for manager-proxy token preflight, auth plugin startup param injection, and invalid auth namespace rejection.
   - `tests/config_test.rs` additions for DSN precedence behavior (URI/query and key-value) and auth plugin parameter capture into `Config.extra`.
4. Updated CONN evidence anchors in `BASELINE_REQUIREMENT_MAPPING.md` to reflect the new code/test evidence.

## Test Commands Run

1. `cargo test --test config_test` -> PASS (`6 passed, 0 failed`)
2. `cargo test preflight_connect_requires_manager_auth_token` -> PASS (`1 passed, 0 failed`)
3. `cargo test build_startup_params_` -> PASS (`2 passed, 0 failed`)

## CONN Status Recommendation

Recommendation: `PARTIAL`

Rationale:
- DSN parsing, precedence checks, direct/manager-proxy mode handling, startup/auth negotiation paths, and auth plugin startup parameter validation now have stronger lane-local evidence.
- Remaining CONN evidence is still incomplete for full `MET` because end-to-end auth/front-door protocol paths are environment-gated in lane tests.

## Remaining Concrete Gaps

1. No deterministic lane test that exercises full on-wire manager-proxy handshake against a controllable MCP endpoint (success + auth failure variants).
2. No deterministic lane test that executes both password and SCRAM-SHA-256 authentication end-to-end on a controlled server fixture (current async integration tests are DSN/env dependent).
3. Capability negotiation remains limited by current lane behavior (`compression=zstd` and `binary_transfer=false` are explicitly rejected), so negotiated feature-path coverage is not complete.
