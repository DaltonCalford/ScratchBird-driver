# DLB-RUST-002 S1 CONN Implementation

Date: 2026-03-06  
Lane: `tracks/alpha/drivers/rust`

## What Changed

1. Closed connection policy parity in `src/config.rs` and `src/client.rs`:
   - Protocol aliases (`jdbc`, `odbc`, `postgresql`, etc.) now normalize to `native`.
   - `sslmode` is normalized/validated (`disable|require|verify-ca|verify-full` + aliases).
   - `compression` is normalized/validated (`off|zstd` + aliases); unknown values are rejected.
   - `binary_transfer=false` and `compression=zstd` are accepted and negotiated instead of hard-rejected.
2. Expanded auth handling in `src/client.rs` handshake:
   - Added runtime support for additional auth request/continue methods (`md5`, `certificate`, `gssapi/sspi`, `ldap`, `saml`, `oidc`, `mfa`, `cluster_pki`) via generic auth payload selection.
   - Added generic auth payload precedence (`auth_payload_b64` -> `auth_payload_json` -> password -> challenge bytes).
3. Added always-on deterministic runtime CONN contract suite in `tests/runtime_contract_gate_test.rs`:
   - Full manager-proxy MCP handshake success path.
   - Deterministic manager-proxy auth failure path.
   - Deterministic on-wire password and SCRAM-SHA-256 auth flows.
   - Capability parity assertions for startup feature bits and query flags under `binary_transfer=false` + `compression=zstd`.

## Tests Run

1. `cargo test`
   - Result: `PASS`

## CONN Status Recommendation

Recommendation: `IMPLEMENTED` (baseline-complete for 0.1.0 scope).

