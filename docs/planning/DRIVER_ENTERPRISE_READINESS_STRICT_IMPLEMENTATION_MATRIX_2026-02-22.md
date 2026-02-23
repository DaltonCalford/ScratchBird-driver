# Driver Enterprise Readiness Strict Matrix (2026-02-22)

## Release Readiness Policy

- Blocked until all P0 tickets for ODBC, .NET/JDBC, and Platform are in `verification_complete`.
- Blocked until all ticket acceptance artifacts are present in:
  - `artifacts/enterprise-readiness/<TICKET>`
- Blocked until all P0 tickets are re-verified after any protocol or transport changes.

## Matrix

### ODBC

| Ticket | Priority | Status | Gap | Acceptance Test | Owner | Risk | ETA | Dependency |
|---|---|---|---|---|---|---|---|
| ODBC-001 | P0 | Verification complete (in-tree ODBC unit suite) | Optional-feature handling returns unsupported-feature paths on BI-required codepaths | BI smoke matrix with no unsupported-feature failures in required paths | ODBC Team | High | 1–2w | None |
| ODBC-002 | P0 | Verification complete (in-tree ODBC unit suite) | `SQLBrowseConnect` not supported for hierarchical object discovery | BI-style browse flows enumerate catalogs, schemas, tables, columns | ODBC Team | High | 1–2w | ODBC-001, ODBC-008 |
| ODBC-003 | P0 | Verification complete (in-tree ODBC unit suite) | Descriptor APIs are partially stubbed/insufficient for typed binding and result metadata | Descriptor conformance for APD/IPD/ARD and output bindings | ODBC Team | High | 2–3w | ODBC-001 |
| ODBC-004 | P0 | Verification complete (in-tree ODBC unit suite) | Metadata query surfaces incomplete for enterprise clients | Golden metadata tests for nested types and object relationships | ODBC Team + QA | High | 2–4w | ODBC-002 |
| ODBC-005 | P0 | Verification complete (in-tree ODBC unit suite) | Scroll and positioned cursor semantics limited | Scrollable/forward-only and positioned update/delete in concurrent load | ODBC Team | High | 2–4w | ODBC-003, ODBC-004 |
| ODBC-006 | P1 | Verification complete (in-tree ODBC unit suite) | Bulk DML and array binding partially implemented | 10k+ row bulk insert/update correctness/performance | ODBC Team | High | 3–5w | ODBC-003 |
| ODBC-007 | P1 | Verification complete (in-tree ODBC unit suite) | LOB read/write streaming incomplete | 10MB+ LOB stream upload/download correctness | ODBC Team | High | 3–5w | ODBC-005 |
| ODBC-008 | P1 | Verification complete (in-tree ODBC unit suite) | `SQLGetInfo` and `SQLGetFunctions` are overly optimistic | Feature matrix test with no false-positive capabilities | ODBC Team + QA | Medium | 2w | ODBC-001 |
| ODBC-009 | P0 | Verification complete (in-tree ODBC gate executed; in-tree BI smoke command mandatory) | Missing external BI-vendor fixture integration in CI | BI runbook automation + conformance + perf/memory checks in CI | Platform Lead + ODBC Team | High | 1w | ODBC-001 .. ODBC-008 |

### .NET/JDBC

| Ticket | Priority | Status | Gap | Acceptance Test | Owner | Risk | ETA | Dependency |
|---|---|---|---|---|---|---|---|
| DOTNET-101 | P1 | Verification complete (integration and cancellation lifecycle assertions passing) | Async and cancellation behavior partially implemented | Cancel long queries without deadlock/connection leaks | .NET Team | High | 2–3w | None |
| DOTNET-102 | P0 | Verification complete | Pooling, reconnection, and stale-handle handling incomplete | Soak test with saturation/failover and bounded leak | .NET Team | High | 3–5w | DOTNET-101 |
| DOTNET-103 | P0 | Verification complete | Lock contention matrix under explicit fault injection remains | Isolation + savepoint matrix across concurrent writers | .NET Team + QA | High | 4–6w | DOTNET-102 |
| DOTNET-104 | P1 | Verification complete (metadata/LOB and cache-lifecycle tests passing) | Metadata/retrieval/LOB paths and statement cache completeness | Metadata and LOB roundtrip matrix, cache invalidation tests | .NET Team | High | 3–5w | DOTNET-101 |
| JDBC-201 | P1 | Verification complete (async timeout and contention assertions passing) | Async/reactive cancellation and contention coverage now implemented | Async cancel and timeout tests under contention | JDBC Team | High | 3–5w | None |
| JDBC-202 | P0 | Verification complete (metadata contract + cached-plan replay/failover protocol path implemented) | Full protocol and metadata parity covered by in-tree JDBC protocol and metadata suites | JDBC conformance and metadata accuracy suite | JDBC Team + QA | High | 4–6w | JDBC-201 |
| JDBC-203 | P0 | In progress (contract and execution harness created) | No cross-runtime pooling contract and release gate | Contract suite passes for .NET/JDBC pooling & recovery | Core Runtime + JVM/Platform | High | 1w | DOTNET-101, JDBC-201, DOTNET-102 |

### Platform

| Ticket | Priority | Status | Gap | Acceptance Test | Owner | Risk | ETA | Dependency |
|---|---|---|---|---|---|---|---|
| PLATFORM-301 | P1 | Missing | No official Helm/sidecar story | Helm + sidecar smoke test in local Kubernetes | Platform Engineering | High | 2–4w | PLATFORM-303 |
| PLATFORM-302 | P0 | Partial | TLS rotation and managed/listener secret behavior unclear | Online rotation with clean reconnects and no drops | Security + Platform Engineering | High | 2–3w | None |
| PLATFORM-303 | P1 | Missing | Secret integration examples incomplete | Docs/examples for short-lived creds and rotation | Platform Engineering | Medium | 2w | None |
| PLATFORM-304 | P0 | Partial | Managed/listener semantics diverge across drivers | Golden matrix for auth/reconnect/timeout/cancel | Platform + Driver Lead | High | 2–4w | PLATFORM-302, PLATFORM-301 |

### Ecosystem

| Ticket | Priority | Status | Gap | Acceptance Test | Owner | Risk | ETA | Dependency |
|---|---|---|---|---|---|---|---|
| ECOSYS-401 | P1 | Missing | No Prisma adapter | Prisma CRUD/transaction/reflection matrix | Ecosystem Team | Medium | 4–8w | ECOSYS-402 |
| ECOSYS-402 | P1 | Missing | No SQLAlchemy dialect package | SQLAlchemy ORM/session/transaction matrix | Ecosystem Team | Medium | 4–8w | JDBC-201, JDBC-202 |
| ECOSYS-403 | P1 | Missing | No Hibernate package | JPA bootstrap/lifecycle/migration tests | Ecosystem Team | Medium | 6–8w | JDBC-202 |
| ECOSYS-404 | P1 | Missing | No TypeORM adapter | Node TypeORM schema/CRUD/transaction suite | Ecosystem Team | Medium | 4–8w | JDBC-201, JDBC-202, PLATFORM-304 |
| ECOSYS-405 | P1 | Incomplete | Python asyncio and Go cancellation semantics incomplete | Async cancel/timeouts in both ecosystems | Platform + Python/Go Drivers | High | 4–6w | None |

## Artifacts and Evidence Standards

- Test artifacts must include command output, environment details, and failure logs.
- Memory and protocol benchmarks for ODBC-009 and JDBC-203 must be versioned in ticket folders.
- Managed/listener behavior tests for PLATFORM-304 must include all core drivers listed in the execution tracker.
