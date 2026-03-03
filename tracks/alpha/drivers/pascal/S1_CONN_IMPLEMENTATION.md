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

## CONN Status Recommendation

- Recommendation: `PARTIAL`

Rationale:
- Lane-local coverage now includes deterministic fail-fast checks for manager-proxy auth prerequisites, TLS mode policy, and key protocol parser guardrails.
- Remaining evidence is still insufficient for `MET` because full end-to-end manager-proxy and direct auth negotiation matrices are not covered by deterministic lane tests.

## Remaining Concrete Gaps

- No deterministic lane fixture test for end-to-end manager-proxy handshake/auth success and auth-failure variants.
- No deterministic lane fixture test matrix for direct front-door auth negotiation variants (password and SCRAM) independent of external environment setup.
- Integration connection tests remain environment-gated (`SCRATCHBIRD_PASCAL_URL`) and can be skipped.
