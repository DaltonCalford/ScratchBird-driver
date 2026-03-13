# DLB-RUBY-002 S1 CONN Implementation

Date: 2026-03-03
Lane: `tracks/p3/drivers/ruby`
Scope: connection/auth/protocol baseline parity improvements with minimal lane-local changes.

## Changes Implemented

1. Connection/auth failure cleanup in client connect path
   - File: `lib/scratchbird/client.rb`
   - Change: wrapped transport/auth/handshake setup in a rescue block that calls `close` and re-raises.
   - Effect: prevents leaked socket/resources when connect fails after TCP/TLS setup (for example, manager-proxy auth preconditions or handshake errors).

2. Namespace alignment required for client initialization
   - Files:
     - `lib/scratchbird/circuit_breaker.rb`
     - `lib/scratchbird/keepalive.rb`
     - `lib/scratchbird/leak_detector.rb`
     - `lib/scratchbird/telemetry.rb`
   - Change: `module ScratchBird` -> `module Scratchbird`.
   - Effect: restores constant resolution used by `Scratchbird::Client` (`CircuitBreaker`, `KeepaliveManager`, `LeakDetector`, `TelemetryCollector`) so connection/auth tests and runtime initialization are valid.

3. New focused CONN/Auth/Protocol unit coverage
   - File: `test/test_conn_auth_protocol.rb`
   - Added coverage:
     - connect guardrails (`user/database`, `binary_transfer`, `compression`, `protocol`, `front_door_mode`)
     - TLS rejection for `sslmode=disable`
     - manager-proxy missing token behavior
     - manager-proxy auth failure payload -> `AuthError`
     - protocol auth-continue parse success/truncation behavior

## Targeted Tests Run

1. `ruby -Itest test/test_conn_auth_protocol.rb`
   - Result: PASS
   - Output summary: `10 runs, 25 assertions, 0 failures, 0 errors, 0 skips`

2. `ruby -Itest test/test_config.rb`
   - Result: PASS
   - Output summary: `4 runs, 21 assertions, 0 failures, 0 errors, 0 skips`

## Final CONN Status Recommendation

Recommendation: `PARTIAL`

Rationale:
- Guardrail/error-path connection/auth/protocol coverage is materially improved and now lane-tested.
- Live positive-path coverage is still missing for manager-proxy and TLS certificate/hostname verification modes.
- SCRAM success/failure behavior still relies on integration environments rather than dedicated deterministic auth-fixture tests.

## Remaining Gaps

1. Add positive-path manager-proxy connect/auth test(s) against a deterministic MCP fixture/server.
2. Add TLS integration tests for `verify-ca` and `verify-full` with fixture certs and hostname checks.
3. Add deterministic SCRAM handshake success/failure tests that exercise full client state transitions across auth frames.
