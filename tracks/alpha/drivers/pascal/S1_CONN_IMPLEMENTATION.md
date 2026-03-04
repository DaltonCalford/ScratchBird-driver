# S1 CONN Implementation (DLB-PASCAL-002)

Scope: `tracks/alpha/drivers/pascal` only.

## What Changed

- Added manager-proxy auth preflight in `src/ScratchBird.Client.pas`:
  - `Connect` now fails fast with `manager_proxy mode requires manager_auth_token` before `FTransport.Configure`/`FTransport.Connect`.
  - This prevents network dial attempts when manager-proxy auth configuration is incomplete.
- Tightened native TLS mode handling in `src/ScratchBird.Transport.Native.pas`:
  - `ParseTlsMode` now rejects `sslmode=disable` during transport configuration with `TLS mode "disable" is not allowed for ScratchBird connections.`.
  - This aligns transport behavior with existing TLS policy (`ScratchBird.Tls.Context` already rejects disable mode).
- Added lane-local connection/auth/protocol tests in `tests/ConnectionAuthProtocolTests.pas`:
  - unsupported protocol guardrail (`protocol=postgresql`) rejection.
  - manager-proxy missing token fail-fast behavior at `TScratchBirdClient.Connect`.
  - native transport `sslmode=disable` configure-time rejection.
  - protocol parser behavior: oversized header rejection and truncated `AUTH_CONTINUE` rejection.
- Added deterministic manager-proxy fixture coverage in `tests/ConnectionManagerProxyTests.pas`:
  - manager-proxy connect success path across MCP negotiation and front-door password auth handshake.
  - manager-proxy auth failure path (`MCP_MSG_AUTH_RESPONSE` failure) mapping to SQLSTATE `28000` and disconnected final state.
  - outbound frame ordering assertions across MCP and native protocol writes.
- Updated CONN evidence and gaps in `BASELINE_REQUIREMENT_MAPPING.md`.

## Targeted Tests Run

1. `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FE./tracks/alpha/drivers/pascal/tests ./tracks/alpha/drivers/pascal/tests/ConnectionAuthProtocolTests.pas`
- Result: PASS (compile succeeded).

2. `./tracks/alpha/drivers/pascal/tests/ConnectionAuthProtocolTests`
- Result: PASS (`ConnectionAuthProtocolTests: OK`).

3. `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FE./tracks/alpha/drivers/pascal/tests ./tracks/alpha/drivers/pascal/tests/ConfigTests.pas`
- Result: PASS (compile succeeded).

4. `./tracks/alpha/drivers/pascal/tests/ConfigTests`
- Result: PASS (`ConfigTests: OK`).

5. `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FU/tmp/sb_pascal_conn_mgr_build -FE/tmp/sb_pascal_conn_mgr_bin ./tracks/alpha/drivers/pascal/tests/ConnectionManagerProxyTests.pas`
- Result: PASS (compile succeeded).

6. `/tmp/sb_pascal_conn_mgr_bin/ConnectionManagerProxyTests`
- Result: PASS (`ConnectionManagerProxyTests: OK`).

## CONN Status Recommendation

- Recommendation: `PARTIAL`

Rationale:
- Lane-local coverage now includes deterministic fail-fast checks for manager-proxy auth prerequisites, TLS mode policy, key protocol parser guardrails, and deterministic end-to-end manager-proxy handshake/auth success and auth-failure paths.
- Remaining evidence is still insufficient for `MET` because direct front-door auth negotiation matrix depth (password/SCRAM variants) remains incomplete in deterministic lane tests.

## Remaining Concrete Gaps

- No deterministic lane fixture test matrix for direct front-door auth negotiation variants (password and SCRAM) independent of external environment setup.
- Integration connection tests remain environment-gated (`SCRATCHBIRD_PASCAL_URL`) and can be skipped.
