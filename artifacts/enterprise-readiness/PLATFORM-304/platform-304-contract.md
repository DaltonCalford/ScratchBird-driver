# PLATFORM-304 Managed/Listener Contract

## Purpose
Prevent semantic drift across drivers in managed/listener mode behavior.

## Contract Surface
For each driver/runtime combination, validate:

1. Handshake behavior
   - Accept managed mode inputs (`front_door_mode=manager_proxy`, `manager_*` fields).
   - Reject malformed managed-mode payloads deterministically.
2. Authentication failure behavior
   - Expired/wrong token produces a stable SQLSTATE class.
   - Error class mapping remains driver-consistent.
3. Reconnect behavior
   - Managed mode reconnect path can recover after transient connection close.
4. Timeout/cancel behavior
   - Cancel path does not hang threads/tasks.
   - Timeout handling closes request state deterministically.
5. Backpressure/retry
   - Reconnect attempts do not exceed local policy window for short transients.

## Evidence Collected
- `run-platform-304-matrix.sh` output matrix.
- Static feature discovery confirms the codebase exposes managed/listener and TLS configuration fields.
- Runtime matrix rows are filled when endpoint env vars are provided.
