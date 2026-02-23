# Driver Enterprise Readiness - Remaining Gaps (Strict) 2026-02-23

## Scope
This list reflects only executable gaps still open after current implementation work.
Each gap is tied to a release blocker and includes owners, risk, and acceptance condition.

## Verification Snapshot (2026-02-23)

- Full-suite command log: `artifacts/enterprise-readiness/verification-sprint-20260223/full_suite_final.log`
- R corrected integration command: `artifacts/enterprise-readiness/verification-sprint-20260223/r_test_corrected.log`
- Current blocker posture:
  - `.NET and JVM paths: in-tree suites pass`
  - `Node`: `tsc` missing in runtime image (`npm run build` fails)
  - `PHP`: `test` script is not defined
  - `Ruby`: no runnable tests discovered
  - `Elixir`: runtime environment has Elixir `~> 1.15` requirement mismatch (1.14 available)
  - `Mojo`, `CLI`, `Python` (partial/optional checks): no dedicated suite or unsupported commands for this environment

| Area | Gap | Severity | Owner | Status | ETA | Required Evidence |
|---|---|---|---|---|---|---|
| DOTNET-101 | Add sustained long-running soak-style async cancellation/release tests (beyond existing stress fixtures). | P1 | .NET Team | In progress | 1-2 weeks | 24-hour style soak evidence with no handle leaks |
| DOTNET-102 | Add failover soak with network reconnection under sustained saturation. | P0 | .NET Team | In progress | 2 weeks | Soak + bounded latency/retry telemetry + leak counters |
| DOTNET-103 | Add lock-deadlock and isolation hardening matrix under fault-injection. | P0 | .NET Team + QA | In progress | 2 weeks | Transaction matrix with explicit serialization and rollback correctness |
| JDBC-203 | Execute cross-runtime (ODBC? no) .NET/JDBC contract in a single runtime with live managed/listener URLs and cancel-SQL variants. | P0 | Core Runtime + JVM/Platform | Blocked | 1 week + env access | End-to-end matrix logs for scenarios A-E |
| Platform-301 | Run Helm + sidecar smoke in live k8s runtime. | P1 | Platform Engineering | Blocked | 1-2 days once cluster available | Sidecar smoke logs + rendered manifests |
| Platform-302 | Run live cert-rotation matrix with active sessions (managed/listener) and verify reconnect behavior. | P0 | Security + Platform | Blocked | 2-3 days once runtime enabled | Rotation pass/fail traces + reconnect status |
| Platform-303 | Validate secret-integration examples against real secret mount/non-interactive startup flow. | P1 | Platform Engineering | Blocked | 1-2 days once runtime available | Smoke and failure-injection logs |
| Platform-304 | Run runtime managed/listener matrix across core drivers and lock in contract deltas. | P0 | Platform + Driver Lead | Blocked | 2-4 days once endpoints available | Runtime matrix matrix artifact with all drivers |
| ECOSYS-401 | Implement Prisma adapter end-to-end and ship passing CRUD/transaction/reflection tests. | P1 | Ecosystem Team | In progress (scaffold) | 4-8 weeks | Sample app + integration test artifact |
| ECOSYS-402 | Implement production SQLAlchemy dialect and sample ORM flow tests. | P1 | Ecosystem Team | In progress (scaffold) | 4-8 weeks | SQLAlchemy introspection + ORM session tests |
| ECOSYS-403 | Implement Hibernate dialect and JPA/bootstrap test flow. | P1 | Ecosystem Team | In progress (scaffold) | 6-8 weeks | JPA bootstrap/lifecycle test artifact |
| ECOSYS-404 | Implement TypeORM adapter with schema/CRUD/transaction tests. | P1 | Ecosystem Team | In progress (scaffold) | 4-8 weeks | Node service + integration tests |
| ECOSYS-405 | Finalize cross-stack async cancellation/timeout contract for Python and Go and verify parity. | P1 | Platform + Driver Team | In progress (scaffold) | 4-6 weeks | Contract suite + reproducible timeout/cancel evidence |

## Run-Blocker Policy
- P0 items and any cross-driver runtime gates must be closed before `verification_complete` state on enterprise milestone.
- Runtime-blocked items are not considered `done`; they remain `blocked` until environment access and artifacts are produced.

## Swift TLS Closure (2026-02-23)

- Status: completed
- Area: Swift Driver TLS transport path now routes TLS options requiring certificate files through `NIOSSL` when available.
- Evidence: 
  - `artifacts/enterprise-readiness/SWIFT-001/latest_verification.log`
  - `tracks/beta/drivers/swift/Tests/ScratchBirdTests/ConfigTests.swift` (transport policy tests for `sslmode=disable`, `binary_transfer=false`, `compression=zstd`).
