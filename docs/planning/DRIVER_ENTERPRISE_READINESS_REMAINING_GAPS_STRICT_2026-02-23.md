# Driver Enterprise Readiness - Remaining Gaps (Strict) 2026-03-06

## Scope
This list reflects only executable gaps still open after current implementation work.
Each gap is tied to a release blocker and includes owners, risk, and acceptance condition.

## Verification Snapshot (2026-03-06)

- Full-suite command log: `artifacts/enterprise-readiness/verification-sprint-20260223/full_suite_final.log`
- R corrected integration command: `artifacts/enterprise-readiness/verification-sprint-20260223/r_test_corrected.log`
- 2026-02-28 local verification additions:
  - `npm install && npm test` passes for Node (integration tests skip when `SCRATCHBIRD_NODE_URL` is unset).
  - `ruby -Ilib:test test/*.rb` passes for Ruby.
  - `composer install && ./vendor/bin/phpunit tests` passes for PHP (integration tests skip in offline mode).
  - `pytest -q` now runs from the Python driver directory without requiring an editable install first.
- Current blocker posture:
  - `.NET and JVM paths: in-tree suites pass; DOTNET-101/102/103 harnesses and JDBC-203 profile-aware gate are implemented`
  - `Elixir`: runtime environment has Elixir `~> 1.15` requirement mismatch (1.14 available)
  - `Mojo`, `CLI` (partial/optional checks): no dedicated suite or unsupported commands for this environment

| Area | Gap | Severity | Owner | Status | ETA | Required Evidence |
|---|---|---|---|---|---|---|
| Platform-301 | Run Helm + sidecar smoke in live k8s runtime. | P1 | Platform Engineering | Blocked | 1-2 days once cluster available | Sidecar smoke logs + rendered manifests |
| Platform-302 | Run live cert-rotation matrix with active sessions (managed/listener) and verify reconnect behavior. | P0 | Security + Platform | Blocked | 2-3 days once runtime enabled | Rotation pass/fail traces + reconnect status |
| Platform-303 | Validate secret-integration examples against real secret mount/non-interactive startup flow. | P1 | Platform Engineering | Blocked | 1-2 days once runtime available | Smoke and failure-injection logs |
| Platform-304 | Run runtime managed/listener matrix across core drivers and lock in contract deltas. | P0 | Platform + Driver Lead | Blocked | 2-4 days once endpoints available | Runtime matrix matrix artifact with all drivers |
| ECOSYS-401 | Implement Prisma adapter end-to-end and ship passing CRUD/transaction/reflection tests. | P1 | Ecosystem Team | In progress (deterministic adapter + migration/reflection workflow helpers + Node contract tests implemented; Prisma CLI runtime currently blocks `provider=\"scratchbird\"`) | 4-8 weeks | Sample app + integration test artifact |
| ECOSYS-402 | Implement production SQLAlchemy dialect and sample ORM flow tests. | P1 | Ecosystem Team | In progress (deterministic dialect + reflection/ORM sample assets + contract tests implemented; live ORM matrix blocked in this shell by non-TLS endpoint/TLS-required driver policy) | 4-8 weeks | SQLAlchemy introspection + ORM session tests |
| ECOSYS-403 | Implement Hibernate dialect and JPA/bootstrap test flow. | P1 | Ecosystem Team | In progress (deterministic Hibernate dialect + contract tests implemented; runtime DriverManager probe now passes with local JDBC jar auto-detected; full JPA lifecycle/migration matrix still pending) | 6-8 weeks | JPA bootstrap/lifecycle test artifact |
| ECOSYS-404 | Implement TypeORM adapter with schema/CRUD/transaction tests. | P1 | Ecosystem Team | In progress (deterministic TypeORM adapter + Node contract tests implemented; TypeORM runtime currently rejects `type=\"scratchbird\"` via MissingDriverError) | 4-8 weeks | Node service + integration tests |
| ECOSYS-405 | Finalize cross-stack async cancellation/timeout contract for Python and Go and verify parity. | P1 | Platform + Driver Team | In progress (deterministic suite implemented; Go live cancel passes; Python live cancel blocked by non-TLS endpoint vs TLS-required Python policy) | 4-6 weeks | Contract suite + reproducible timeout/cancel evidence with both ecosystems passing live cancel matrix |

## Run-Blocker Policy
- P0 items and any cross-driver runtime gates must be closed before `verification_complete` state on enterprise milestone.
- Runtime-blocked items are not considered `done`; they remain `blocked` until environment access and artifacts are produced.

## Swift TLS Closure (2026-02-23)

- Status: completed
- Area: Swift Driver TLS transport path now routes TLS options requiring certificate files through `NIOSSL` when available.
- Evidence: 
  - `artifacts/enterprise-readiness/SWIFT-001/latest_verification.log`
  - `tracks/p3/drivers/swift/Tests/ScratchBirdTests/ConfigTests.swift` (transport policy tests for `sslmode=disable`, `binary_transfer=false`, `compression=zstd`).
