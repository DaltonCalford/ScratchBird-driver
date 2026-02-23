# PLATFORM-302 TLS Rotation Runbook

## Scope
Validate certificate rotation for managed/listener transports without full service restart.

## Supported Inputs
- Mounted file replacement (`--mount`ed secret)
- Environment-reload mode for file-backed DSNs and process watch
- Manual provider-driven cert reload path (future manager-provider integration)

## Minimum Environment
- `openssl` available.
- For runtime checks only:
  - A reachable ScratchBird server in managed/listener mode.
  - Correct client credentials for the corresponding mode.
  - Any runtime driver that accepts managed/listener connection options.

## Procedure (Local Simulation, no live server)
1. Generate temporary CA and server certificate/keys with `openssl`.
2. Start with `server-cert-1.pem` + `server-key-1.pem`.
3. Record fingerprint/hash of current cert as baseline.
4. Replace with `server-cert-2.pem` + `server-key-2.pem` in a watch location.
5. Verify:
   - Both cert files are readable by runtime processes.
   - The file mtime and hash change as expected.
   - The client can still open a new TLS context using refreshed paths.
6. If possible, rerun a small smoke query before and after swap and measure reconnect delay.

## Procedure (Runtime Rotation, Optional)
1. Configure managed/listener client in a test namespace to use a mounted cert secret.
2. Deploy/attach long-lived session and keep a baseline query loop running.
3. Atomically update secret version and force a controlled file refresh.
4. Confirm:
   - New sessions can negotiate with new cert.
   - Existing sessions either reconnect within SLO or fail safely and recover.
5. Verify that invalid certificate material causes deterministic auth/failover behavior.

## Failure Modes
- `sslmode=disable` or insecure mode accepted unintentionally.
- Client path ignores cert path changes until full process restart (unexpected for managed/listener mode).
- Rotation path requires manual intervention for every client mode.
- Certificate parsing succeeds but rotation not observed in logs.

## Artifacts
- `artifacts/enterprise-readiness/PLATFORM-302/run-platform-302-tls-rotation-matrix.sh`
- `artifacts/enterprise-readiness/PLATFORM-302/rotation-matrix.csv`
- `artifacts/enterprise-readiness/PLATFORM-302/rotation-smoke.log`
