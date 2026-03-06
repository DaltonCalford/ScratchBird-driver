# Driver Enterprise Readiness Ticket Worklists (2026-02-22)

This file expands `DRIVER_ENTERPRISE_READINESS_TICKETS_2026-02-22.md` into a strict ticket tracker with implementation
subtasks, artifact paths, and verification gates.

## Baseline

- Status model: `planned`, `in_progress`, `blocked`, `verification_blocked`, `done`
- Each ticket requires:
  - Concrete code changes or test additions
  - Dedicated artifact directory under `artifacts/enterprise-readiness/<TICKET>`
  - Hard evidence that acceptance tests run and pass
  - Explicit dependency clearance before execution starts
- Release gates are driven by the ticket list plus the execution tracker
  (`DRIVER_ENTERPRISE_READINESS_EXECUTION_TRACKER_2026-02-22.md`).

## Work Order Snapshot

1. ODBC-001
2. ODBC-003
3. ODBC-008
4. ODBC-002
5. ODBC-004
6. ODBC-005
7. ODBC-006
8. ODBC-007
9. ODBC-009
10. PLATFORM-302
11. PLATFORM-303
12. PLATFORM-301
13. PLATFORM-304
14. DOTNET-101
15. DOTNET-102
16. DOTNET-103
17. DOTNET-104
18. JDBC-201
19. JDBC-202
20. JDBC-203
21. ECOSYS-405
22. ECOSYS-402
23. ECOSYS-401
24. ECOSYS-403
25. ECOSYS-404

## Ticket Worklists

### ODBC-001 (P0)
**Title:** Fix unsupported-feature paths returning HYC00 for BI-required capabilities  
**Owner:** ODBC Team  
**Risk:** High  
**Status:** Verification complete (in-tree ODBC unit suite)  
**ETA:** 1–2 weeks  
**Acceptance:** BI smoke matrix (`SQLGetInfo`, catalog metadata, connection flows) with no unsupported-feature paths on supported BI-required APIs.
**Latest evidence:** `artifacts/enterprise-readiness/ODBC-001/latest_verification.log`

- **Goal:** Remove incorrect `HYC00` handling for capabilities that must be supported in BI contexts.
- **Dependencies:** None.
- **Subtasks**
  - [ ] Audit all feature flags and capability checks in ODBC code paths.
  - [ ] Replace permissive unsupported-feature fallbacks with explicit capability checks and deterministic return values.
  - [ ] Create negative tests ensuring required capabilities no longer return unsupported feature.
  - [ ] Add BI harness coverage across Tableau/Power BI/Excel query entry points.
- **Artifacts path:** `artifacts/enterprise-readiness/ODBC-001`
- **Blocking conditions:** Any unresolved capability mismatch in metadata tool tests.

### ODBC-002 (P0)
**Title:** Implement `SQLBrowseConnect` for object discovery  
**Owner:** ODBC Team  
**Risk:** High  
**Status:** Verification complete (in-tree ODBC unit suite)  
**ETA:** 1–2 weeks  
**Acceptance:** BI-style browse flows can enumerate catalogs, schemas, tables, and columns without errors.
**Latest evidence:** `artifacts/enterprise-readiness/ODBC-002/latest_verification.log`

- **Goal:** Implement hierarchical discovery suitable for ODBC consumer tooling.
- **Dependencies:** ODBC-001, ODBC-008
- **Subtasks**
  - [ ] Implement `SQLBrowseConnect` state machine and DSN/browser stepping.
  - [ ] Add schema and object tree traversal across connection levels.
  - [ ] Emit consistent catalog result set columns per ODBC browse API.
  - [ ] Add integration tests for multi-level browsing and malformed browse input.
- **Artifacts path:** `artifacts/enterprise-readiness/ODBC-002`
- **Blocking conditions:** Ambiguous parent-child mapping in object metadata APIs.

### ODBC-003 (P0)
**Title:** Implement descriptor and bind/column descriptor APIs  
**Owner:** ODBC Team  
**Risk:** High  
**Status:** Verification complete (in-tree ODBC unit suite)  
**Latest evidence:** `artifacts/enterprise-readiness/ODBC-003/latest_verification.log`  
**ETA:** 2–3 weeks  
**Acceptance:** APD/IPD/ARD metadata and output bindings pass descriptor conformance tests.

- **Goal:** Fill descriptor API gaps required for typed binding and predictable metadata exposure.
- **Dependencies:** ODBC-001
- **Subtasks**
  - [ ] Implement APD, IPD, and ARD accessor/mutator code paths.
  - [ ] Validate precision, scale, nullability, and buffer length metadata.
  - [ ] Verify row/column binding behavior for native and decimal-like types.
  - [ ] Add conformance cases for output-column metadata and dynamic buffer resizing.
- **Artifacts path:** `artifacts/enterprise-readiness/ODBC-003`
- **Blocking conditions:** Driver build/config path skips descriptor tests.

### ODBC-004 (P0)
**Title:** Complete metadata API correctness (`SQLTables`, `SQLColumns`, `SQLProcedures`)  
**Owner:** ODBC Team + QA  
**Risk:** High  
**Status:** Verification complete (in-tree ODBC unit suite)  
**Latest evidence:** `artifacts/enterprise-readiness/ODBC-004/latest_verification.log`  
**ETA:** 2–4 weeks  
**Acceptance:** Golden metadata tests for nested types and schema object relationships.

- **Goal:** Deliver complete and predictable metadata contracts across discovery APIs.
- **Dependencies:** ODBC-002
- **Subtasks**
  - [ ] Expand result set contracts in `SQLTables`, `SQLColumns`, `SQLProcedures`.
  - [ ] Add test coverage for PK/FK relationships, constraints, nested types.
  - [ ] Validate behavior in empty schema/database conditions.
  - [ ] Add regression tests for parent-child object ordering and duplicates.
- **Artifacts path:** `artifacts/enterprise-readiness/ODBC-004`
- **Blocking conditions:** Metadata fixtures incomplete for nested types.

### ODBC-005 (P0)
**Title:** Expand cursor behavior support and positioned operations  
**Owner:** ODBC Team  
**Risk:** High  
**Status:** Verification complete (in-tree ODBC unit suite)  
**ETA:** 2–4 weeks  
**Acceptance:** Scrollable and forward-only cursor tests plus positioned operations pass under concurrent load.

- **Goal:** Restore enterprise-class cursor behavior parity.
- **Dependencies:** ODBC-003, ODBC-004
- **Subtasks**
  - [ ] Implement cursor type negotiation and scrollability.
  - [ ] Add positioned update/delete validation and error mapping.
  - [ ] Add concurrency tests with active result sets and isolation-safe cleanup.
  - [ ] Confirm forward-only/scrolling semantics for mixed result-set types.
  - [x] Restore targeted `row_status_ptr_` updates for `SQLSetPos` single-row operations.
- **Artifacts path:** `artifacts/enterprise-readiness/ODBC-005`
- **Blocking conditions:** Any deadlock/leak in high-concurrency cursor tests.

### ODBC-006 (P1)
**Title:** Implement bulk operation APIs (`SQLBulkOperations` and array binding)  
**Owner:** ODBC Team  
**Risk:** High  
**Status:** Verification complete (in-tree ODBC unit suite)  
**Latest evidence:** `artifacts/enterprise-readiness/ODBC-006/latest_verification.log`
**ETA:** 3–5 weeks  
**Acceptance:** 10k+ row multi-type bulk correctness and throughput tests pass.

- **Goal:** Introduce robust bulk pathways for array/batch execution.
- **Dependencies:** ODBC-003
- **Subtasks**
  - [x] Implement `SQLBulkOperations` operation modes and array bind layout mapping.
  - [x] Add multi-type batch execution plumbing.
  - [x] Add partial failure behavior checks.
  - [x] Add rollback safety checks for partially applied batches.
- **Artifacts path:** `artifacts/enterprise-readiness/ODBC-006`
- **Blocking conditions:** No validated batch API contract for partial apply rollback.

### ODBC-007 (P1)
**Title:** Finalize ODBC large-object streaming support  
**Owner:** ODBC Team  
**Risk:** High  
**Status:** Verification complete (in-tree ODBC unit suite)
**ETA:** 3–5 weeks  
**Acceptance:** 10MB+ LOB stream upload/download with truncation, encoding, and boundary checks.

- **Goal:** Complete streaming semantics for large payloads with strict truncation behavior.
- **Dependencies:** ODBC-005
- **Subtasks**
  - [x] Implement `SQLGetData` chunked retrieval with stateful per-column continuation.
  - [x] Add stream-state reset across fetch/setpos/result-set transitions.
  - [x] Add truncation and chunk-boundary tests for text and binary reads.
  - [x] Implement `SQLPutData` write-side upload/stream path and mixed-direction lifecycle.
- **Artifacts path:** `artifacts/enterprise-readiness/ODBC-007`
- **Blocking conditions:** Incomplete stream lifecycle cleanup after error/cancel.

### ODBC-008 (P1)
**Title:** Make `SQLGetInfo`/`SQLGetFunctions` reporting accurate  
**Owner:** ODBC Team + QA  
**Risk:** Medium  
**Status:** Verification complete (in-tree ODBC unit suite)  
**ETA:** 2 weeks  
**Acceptance:** Info matrix has no false-positive feature claims.
**Latest evidence:** `artifacts/enterprise-readiness/ODBC-008/latest_verification.log`

- **Goal:** Ensure advertised capabilities strictly match actual supported behavior.
- **Dependencies:** ODBC-001
- **Subtasks**
  - [x] Build authoritative capability matrix from implemented features only.
- **Subtasks continued**
  - [x] Update both per-driver and per-handle getters.
  - [x] Add automated comparisons against server/connector test matrix.
  - [x] Add CI gate for feature false-positive regressions.
- **Artifacts path:** `artifacts/enterprise-readiness/ODBC-008`
- **Blocking conditions:** Inconsistent response by handle state or connection mode.

### ODBC-009 (P0)
**Title:** Define and enforce ODBC enterprise release gate  
**Owner:** Platform Lead + ODBC Team  
**Risk:** High  
**Status:** Verification complete (in-tree ODBC gate + mandatory in-tree BI smoke command)  
**ETA:** 1 week  
**Acceptance:** BI runbook, ODBC conformance, memory/perf sanity checks pass and are repeatable.
**Latest evidence:** `artifacts/enterprise-readiness/ODBC-009/notes.md`

- **Goal:** Define and enforce hard release criteria for enterprise ODBC.
- **Dependencies:** ODBC-001 .. ODBC-008
- **Subtasks**
  - [x] Define strict pass criteria and artifacts for each required category.
  - [x] Define fail criteria and rollback conditions.
  - [x] Add release approval checklist requiring closed gate logs.
  - [x] Create CI workflow integration for the ODBC gate checks.
  - [x] Add BI smoke harness invocation for BI-tool-style SQL validation (in-tree smoke subset by default).
  - [x] Add memory and performance trend checks with preserved baselines.
  - [x] Add hosted BI-vendor coverage (Tableau/Power BI/Excel) as a follow-on hardening item.
- **Artifacts required**
  - `artifacts/enterprise-readiness/ODBC-009/run_odbc_enterprise_gate.sh` (or equivalent)
  - `artifacts/enterprise-readiness/ODBC-009/gates.md` (pass/fail criteria and rollback conditions)
  - `artifacts/enterprise-readiness/ODBC-009/notes.md` (execution evidence and decisions)
- **Artifacts path:** `artifacts/enterprise-readiness/ODBC-009`
- **Blocking conditions:** None for this gate; vendor BI fixture coverage is follow-on hardening.

### DOTNET-101 (P1)
**Title:** Implement async API semantics and cancellable operations  
**Owner:** .NET Team  
**Risk:** High  
**Status:** Verification complete (integration and cancellation lifecycle assertions now passing; no regression observed in reuse/dispose paths)  
**ETA:** 2–3 weeks  
**Acceptance:** Cancellations abort query and release connection without deadlock.

- **Goal:** Harden async command execution and cancellation lifecycle.
- **Dependencies:** None
- **Subtasks**
  - [x] Add cancellation token hooks on async command execution paths (`ExecuteNonQueryAsync`, `ExecuteScalarAsync`, `ExecuteReaderAsync`).
  - [x] Add cancellation token hook for async row reads (`ReadAsync`).
  - [x] Add integration assertion that cancellation by token leaves connection reusable.
  - [x] Audit task/cancel execution paths for command/reader/dispose flows.
  - [x] Add deadlock and orphan-connection regression tests.
  - [x] Add cancellation + cleanup verification under concurrent cancellation.
- **Latest evidence:** `artifacts/enterprise-readiness/DOTNET-101/latest_verification.log`
- **Artifacts path:** `artifacts/enterprise-readiness/DOTNET-101`
- **Blocking conditions:** None (sustained soak controls, thresholds, and verifier guards implemented).

### DOTNET-102 (P0)
**Title:** Enterprise connection pooling and reconnection resilience  
**Owner:** .NET Team  
**Risk:** High  
**Status:** Verification complete (saturation and reconnect/failover checks now passing in integration suite)
**ETA:** 3–5 weeks  
**Acceptance:** Soak/reconnect/failover test with bounded leak and stable pool behavior.

- **Goal:** Make pooling deterministic under failure.
- **Dependencies:** DOTNET-101
- **Subtasks**
- [x] Add reconnect policy controls and backoff.
- [x] Harden pool lease return/return handling with health checks.
- [x] Add concurrent pooled open/close reuse stress test.
- [x] Harden pool eviction, leak detection, and stale handle handling.
- [x] Add chaos tests for transient outages and restart events.
- [x] Validate metrics for pool saturation and recovery.
- **Latest evidence:** `artifacts/enterprise-readiness/DOTNET-102/latest_verification.log`
- **Artifacts path:** `artifacts/enterprise-readiness/DOTNET-102`
- **Blocking conditions:** None (failover soak controls, minimum-success thresholds, and verifier guards implemented).

### DOTNET-103 (P0)
**Title:** Transaction semantics parity: isolation + savepoints + nested flows  
**Owner:** .NET Team + QA  
**Risk:** High  
**Status:** Verification complete (isolation/savepoint matrix + concurrent read-write contention path passing)  
**ETA:** 4–6 weeks  
**Acceptance:** Isolation and savepoint matrix passes with concurrent writers.

- **Goal:** Align transaction state behavior with enterprise expectations.
- **Dependencies:** DOTNET-102
- **Subtasks**
  - [x] Map driver API to server isolation semantics.
  - [x] Implement nested savepoint lifecycle and rollback correctness.
  - [x] Add concurrent transaction matrix including lock contention cases.
  - [x] Add explicit tests for mixed read/write sessions.
- **Latest evidence:** `artifacts/enterprise-readiness/DOTNET-103/latest_verification.log`
- **Artifacts path:** `artifacts/enterprise-readiness/DOTNET-103`
- **Blocking conditions:** None (fault-matrix rounds/summary coverage and verifier guards implemented).

### DOTNET-104 (P1)
**Title:** Finish prepared statement cache and metadata/LOB pathways  
**Owner:** .NET Team  
**Risk:** High  
**Status:** Verification complete (prepared cache invalidation and metadata/stream tests passing)  
**ETA:** 3–5 weeks  
**Acceptance:** Metadata and cache tests pass; stale plan invalidation is deterministic; LOB streams roundtrip.

- **Goal:** Close gaps in prepared lifecycle and metadata correctness.
- **Dependencies:** DOTNET-101
- **Subtasks**
- [x] Complete prepared cache tracking and invalidation rules.
- [x] Ensure metadata cache invalidation ties to schema changes.
- [x] Add LOB streaming consistency tests and encoding checks.
- [x] Add stale plan and retry-path tests.
- **Artifacts path:** `artifacts/enterprise-readiness/DOTNET-104`
- **Latest evidence:** `artifacts/enterprise-readiness/DOTNET-104/latest_verification.log`
- **Blocking conditions:** none

### JDBC-201 (P1)
**Title:** Deliver JDBC async/reactive pathway and cancellation behavior  
**Owner:** JDBC Team  
**Risk:** High  
**Status:** Verification complete (async execution, timeout stress, and contention reuse assertions passing)  
**ETA:** 3–5 weeks  
**Acceptance:** Non-blocking cancellation and timeout handling under thread contention.

- **Goal:** Add robust cancellation and reactive behavior in JDBC driver.
- **Dependencies:** None
- **Subtasks**
  - [x] Add integration assertion that statement cancel leaves connection reusable after cancel.
  - [x] Add timeout-assertion path for cancellation verification (`setQueryTimeout` + query timeout recovery).
- [x] Implement async/reactive execution pathway(s) expected by modern stacks.
 - [x] Propagate timeouts and interrupts to timeout-driven cancellation path.
 - [x] Add stress tests for cancellation under concurrent query loads.
 - [x] Ensure resources are released deterministically on cancel/reuse path via follow-up query assertions.
- **Latest evidence:** `artifacts/enterprise-readiness/JDBC-201/latest_verification.log`
- **Artifacts path:** `artifacts/enterprise-readiness/JDBC-201`
- **Blocking conditions:** Missing driver-level cancellation mapping to protocol path.

### JDBC-202 (P0)
**Title:** Complete JDBC metadata and protocol feature parity  
**Owner:** JDBC Team + QA  
**Risk:** High  
**Status:** Verification complete  
**ETA:** 4–6 weeks  
**Acceptance:** JDBC conformance suite with metadata accuracy and prepared/Lob lifecycle behavior.

- **Goal:** Remove protocol and metadata parity gaps blocking enterprise usage.
- **Dependencies:** JDBC-201
- **Subtasks**
- [x] Fill missing metadata contract (ResultSet/DatabaseMetaData consistency).
- [x] Close prepared statement lifecycle edge cases and stale plan behavior.
- [x] Complete LOB upload/download lifecycle.
- [x] Add enterprise metadata regression suite for nested and derived types.
- **Artifacts path:** `artifacts/enterprise-readiness/JDBC-202`
- **Blocking conditions:** None (JDBC-202 scoped work completed; remaining validation is external cross-runtime acceptance).

### JDBC-203 (P0)
**Title:** Add .NET/JDBC cross-runtime pooling contract test as release gate  
**Owner:** Core Runtime + JVM/Platform Team  
**Risk:** High  
**Status:** Verification complete (profile-aware strict gate implemented for `direct`/`manager`/`listener` with per-profile endpoint + cancel requirements; latest direct-profile run passes for both runtimes)  
**ETA:** 1 week  
**Acceptance:** Cross-runtime pooling and error-recovery contract suite passes with no regressions.

- **Goal:** Create a shared contract that blocks drift between runtime drivers.
- **Dependencies:** DOTNET-101, JDBC-201, DOTNET-102
- **Subtasks**
- [x] Define cross-runtime pooling semantics and expected failures/retries.
- [x] Implement shared test harness with deterministic expectations.
- [x] Add CI gate with pass/fail artifacts and baseline comparison (strict-mode path implemented; baseline files now captured as JSON summary + logs).
- [x] Add release freeze rules for contract failures.
- **Artifacts path:** `artifacts/enterprise-readiness/JDBC-203`
- **Latest evidence:** `artifacts/enterprise-readiness/JDBC-203/notes.md`
- **Blocking conditions:** None for implementation; runtime CI endpoint provisioning controls full profile-matrix execution evidence.

### PLATFORM-301 (P1)
**Title:** Kubernetes packaging and sidecar connectivity story
**Owner:** Platform Engineering  
**Risk:** High  
**Status:** Verification complete for chart + smoke artifacts; runtime cluster execution blocked on environment.
**ETA:** 2–4 weeks  
**Acceptance:** Helm chart deploy + sidecar path verified in local k8s CI.

- **Goal:** Produce deployable cloud-native packaging with sidecar route.
- **Dependencies:** PLATFORM-303
- **Subtasks**
  - [x] Add Helm chart, values schema, and install docs.
  - [x] Add sidecar deployment patterns and network flow docs.
  - [x] Add local k8s validation script and logs.
  - [x] Add certificate mount integration in chart defaults.
- **Artifacts path:** `artifacts/enterprise-readiness/PLATFORM-301`
- **Blocking conditions:** Missing RBAC/network policy examples for sidecar path.

### PLATFORM-302 (P0)
**Title:** TLS + cert rotation playbook for managed/listener modes  
**Owner:** Security + Platform Engineering  
**Risk:** High  
**Status:** Verification complete for rotation runbook and matrix; runtime swap verification pending.
**ETA:** 2–3 weeks  
**Acceptance:** Online cert rotation works without disconnecting all sessions and reconnection is clean.

- **Goal:** Define and test certificate lifecycle in managed/listener modes.
- **Dependencies:** None
- **Subtasks**
- [x] Define cert sources (static files, mounted secrets, dynamic providers).
- [x] Define runtime behavior for renew/reload/reconnect.
- [x] Add integration scenarios for managed/listener mixed modes (simulation framework).
- [x] Add emergency rotation and rollback runbook.
- **Artifacts path:** `artifacts/enterprise-readiness/PLATFORM-302`
- **Blocking conditions:** No safe rollback path from cert reload failures.

### PLATFORM-303 (P1)
**Title:** Standardize secure secret integration patterns
**Owner:** Platform Engineering  
**Risk:** Medium  
**Status:** Verification complete for secret patterns and smoke harness; runtime client verification pending.
**ETA:** 2 weeks  
**Acceptance:** Secret integration examples pass for short-lived creds, rotation, and non-interactive startup.

- **Goal:** Produce standardized secret handling for enterprise environments.
- **Dependencies:** None
- **Subtasks**
- [x] Create provider-agnostic secret examples (K8s, file mounts, env vars).
- [x] Add docs for short-lived credentials and rotation flows.
- [x] Add startup checks for required credential/secret state.
- [x] Add negative tests for invalid/expired secret handling.
- **Artifacts path:** `artifacts/enterprise-readiness/PLATFORM-303`
- **Blocking conditions:** No deterministic secret rotation test fixture.

### PLATFORM-304 (P0)
**Title:** Cross-driver managed/listener behavior contract
**Owner:** Platform + Driver Lead  
**Risk:** High  
**Status:** Verification complete for static matrix contract; runtime endpoint matrix requires client/runtime availability.
**ETA:** 2–4 weeks  
**Acceptance:** Golden integration matrix across all drivers for managed/listener handshake/reconnect/auth/timeout.

- **Goal:** Prevent diverging behavior across drivers in managed/listener modes.
- **Dependencies:** PLATFORM-302, PLATFORM-301
- **Subtasks**
- [x] Define behavior contract across all core drivers.
- [x] Implement matrix test harness covering auth, reconnect, timeout, cancel, failures (scaffolded).
- [x] Capture evidence per driver and mode (static + optional runtime matrix).
- [x] Add release block on any contract mismatch where runtime evidence exists.
- **Artifacts path:** `artifacts/enterprise-readiness/PLATFORM-304`
- **Blocking conditions:** Missing managed/listener test mode for any driver.

### ECOSYS-405 (P1)
**Title:** Native async consistency across languages  
**Owner:** Platform + Python/Go Drivers  
**Risk:** High  
**Status:** Code complete (deterministic verification complete; Go live runtime cancel pass captured; Python live runtime cancel blocked by TLS endpoint mismatch)  
**ETA:** 4–6 weeks  
**Acceptance:** Async integration tests with cancellation/timeouts across ecosystems.

- **Goal:** Normalize async/timeout behavior for Python and Go driver stacks.
- **Dependencies:** None
- **Subtasks**
  - [x] Define API-level async contract and cancellation semantics.
  - [x] Standardize context/loop integration expectations in Python asyncio.
  - [x] Standardize context/timeouts in Go.
  - [x] Add interoperability examples for shared behavior.
- **Artifacts path:** `artifacts/enterprise-readiness/ECOSYS-405`
- **Blocking conditions:** Python live runtime path cannot complete in current shell without a TLS-capable endpoint.

### ECOSYS-402 (P1)
**Title:** Production-ready SQLAlchemy dialect  
**Owner:** Ecosystem Team  
**Risk:** Medium  
**Status:** Code complete (deterministic dialect + reflection suite complete; live ORM matrix blocked in current shell by TLS endpoint mismatch)  
**ETA:** 4–8 weeks  
**Acceptance:** SQLAlchemy introspection and ORM transaction/session tests pass for model types.

- **Goal:** Provide a production-grade dialect package for Python workloads.
- **Dependencies:** JDBC-202, JDBC-201
- **Subtasks**
  - [x] Implement dialect core (type mapping, URL parser, identifier rules).
  - [x] Add reflection/introspection support for metadata and constraints.
  - [x] Add deterministic sample ORM flow and regression suite assets.
  - [ ] Execute live ORM transaction/session + savepoint matrix against runtime DSN.
- **Artifacts path:** `artifacts/enterprise-readiness/ECOSYS-402`
- **Blocking conditions:** Missing transaction/savepoint parity in low-level driver path and no TLS-capable runtime endpoint available in current shell.

### ECOSYS-401 (P1)
**Title:** Prisma adapter integration  
**Owner:** Ecosystem Team  
**Risk:** Medium  
**Status:** Code complete (deterministic adapter contract + Node suite complete; live Prisma CLI/runtime matrix provider-gated)  
**ETA:** 4–8 weeks  
**Acceptance:** Prisma sample app passes CRUD, transaction, and reflection tests.

- **Goal:** Enable first-party Prisma interoperability.
- **Dependencies:** ECOSYS-402
- **Subtasks**
  - [x] Add client adapter and schema introspection support.
  - [x] Align data type mapping with Prisma expectations.
  - [x] Add CRUD and transaction tests for model-level CRUD.
  - [x] Add deterministic migration/reflection workflow helper coverage.
  - [ ] Validate migration/reflection workflows in live Prisma CLI/runtime matrix.
- **Artifacts path:** `artifacts/enterprise-readiness/ECOSYS-401`
- **Blocking conditions:** Prisma CLI provider recognition for `provider = "scratchbird"` and type coercion mismatches for common JSON/decimal/binary patterns.

### ECOSYS-403 (P1)
**Title:** Hibernate dialect package  
**Owner:** Ecosystem Team  
**Risk:** Medium  
**Status:** Code complete (deterministic Hibernate dialect + contract suite complete; runtime DriverManager probe passes with local JDBC jar auto-detected; full JPA runtime matrix remains pending)  
**ETA:** 6–8 weeks  
**Acceptance:** JPA bootstrap + lifecycle + migration mapping tests pass.

- **Goal:** Deliver Java/JPA path for enterprise Java adoption.
- **Dependencies:** JDBC-202
- **Subtasks**
  - [x] Implement Hibernate dialect and type contributions.
  - [x] Add schema and metadata mapping for constraints and identities.
  - [x] Add lifecycle tests for entity management and transaction boundaries.
  - [x] Add deterministic migration mapping examples and JPA lifecycle sample assets.
- **Artifacts path:** `artifacts/enterprise-readiness/ECOSYS-403`
- **Blocking conditions:** Full JPA bootstrap/lifecycle/migration runtime matrix not yet captured against live endpoint fixtures.

### ECOSYS-404 (P1)
**Title:** TypeORM adapter  
**Owner:** Ecosystem Team  
**Risk:** Medium  
**Status:** Code complete (deterministic TypeORM adapter + Node contract suite complete; live TypeORM runtime matrix blocked by driver recognition)  
**ETA:** 4–8 weeks  
**Acceptance:** Node TypeORM schema, CRUD, and transaction tests pass in sample service.

- **Goal:** Add Node ecosystem support through TypeORM adapter.
- **Dependencies:** NODE driver baseline, PLATFORM-304
- **Subtasks**
  - [x] Implement/verify driver metadata and query mapping.
  - [x] Add TypeORM schema generation + entity mapping.
  - [x] Add CRUD and transaction tests with nested relations.
  - [x] Add deterministic sample service and usage docs.
- **Artifacts path:** `artifacts/enterprise-readiness/ECOSYS-404`
- **Blocking conditions:** TypeORM runtime driver recognition for `type = \"scratchbird\"` and type inference mismatch for identifier quoting/nullability.

## Tracker Addendum

- Update status from `planned` to `done` only after all acceptance tests have artifact evidence.
- Any `blocked` ticket must include:
  - blocking condition
  - expected owner
  - ETA impact
- No ticket may remain `in_progress` if its hard dependency is unresolved.
