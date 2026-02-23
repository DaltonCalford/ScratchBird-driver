# Driver Enterprise Readiness Tickets (2026-02-22)

This file is the canonical ticket list. Detailed ticket subtasks are in
`DRIVER_ENTERPRISE_READINESS_TICKET_WORKLISTS_2026-02-22.md`,
and strict dependency/acceptance matrix is in
`DRIVER_ENTERPRISE_READINESS_STRICT_IMPLEMENTATION_MATRIX_2026-02-22.md`.

## ODBC Workstream

### ODBC-001
Title: Fix unsupported-feature paths returning HYC00 for BI-required capabilities  
Priority: P0  
Status: Verification complete (in-tree ODBC unit suite)  
Gap: Optional-feature handling is not enterprise-safe for core BI metadata/capability flows  
Acceptance Test: Full ODBC BI smoke matrix (`SQLGetInfo`, catalog/browser metadata, and standard connection queries) with no `HYC00` on supported BI paths  
Owner: ODBC Team  
Risk: High  
ETA: 1–2 weeks

### ODBC-002
Title: Implement `SQLBrowseConnect` for object discovery  
Priority: P0  
Status: Verification complete (in-tree ODBC unit suite)  
Gap: Hierarchical DSN/connection browsing not supported  
Acceptance Test: BI-style browse flows can enumerate catalogs/schemas/tables/columns without errors  
Owner: ODBC Team  
Risk: High  
ETA: 1–2 weeks

### ODBC-003
Title: Implement descriptor and bind/column descriptor APIs  
Priority: P0  
Status: Verification complete (in-tree ODBC unit suite)  
Gap: Descriptor handling is stubbed/insufficient for typed binding and result metadata  
Acceptance Test: Descriptor conformance tests covering `APD`/`IPD`/`ARD` metadata, precision/scale/nullability/length, and output bindings  
Owner: ODBC Team  
Risk: High  
ETA: 2–3 weeks

### ODBC-004
Title: Complete metadata API correctness (`SQLTables`, `SQLColumns`, `SQLProcedures`)  
Priority: P0  
Status: Verification complete (in-tree ODBC unit suite)  
Gap: Metadata query surfaces are simplified and incomplete for enterprise clients  
Acceptance Test: Golden metadata tests for nested types, constraints, and key/parent-child relationships across schemas  
Owner: ODBC Team + QA  
Risk: High  
ETA: 2–4 weeks

### ODBC-005
Title: Expand cursor behavior support and positioned operations  
Priority: P0  
Status: Verification complete (in-tree ODBC unit suite)  
Gap: Scroll and positioned semantics are limited  
Acceptance Test: Scrollable and forward-only cursor tests plus positioned update/delete pass under concurrent load  
Owner: ODBC Team  
Risk: High  
ETA: 2–4 weeks  

### ODBC-006
Title: Implement bulk operation APIs (`SQLBulkOperations` and array binding)  
Priority: P1  
Status: Verification complete (in-tree ODBC unit suite)  
Gap: Bulk DML/array handling not available  
Acceptance Test: Bulk insert/update performance and correctness suite (10k+ rows, multi-type columns)  
Owner: ODBC Team  
Risk: High  
ETA: 3–5 weeks

### ODBC-007
Title: Finalize ODBC large-object streaming support  
Priority: P1  
Status: Verification complete (in-tree ODBC unit suite)
Gap: LOB read/write behavior is incomplete/inconsistent for enterprise payload sizes  
Acceptance Test: 10MB+ LOB stream upload/download with boundary/encoding/truncation checks  
Owner: ODBC Team  
Risk: High  
ETA: 3–5 weeks

### ODBC-008
Title: Make `SQLGetInfo`/`SQLGetFunctions` reporting accurate  
Priority: P1  
Status: Verification complete (in-tree ODBC unit suite)  
Gap: Info responses are optimistic and may mislead clients  
Acceptance Test: ODBC Info matrix test against documented/advertised capabilities; no false-positive feature claims  
Owner: ODBC Team + QA  
Risk: Medium  
ETA: 2 weeks

### ODBC-009
Title: Define and enforce ODBC enterprise release gate  
Priority: P0  
Status: Not yet defined  
Gap: No explicit release criteria for enterprise readiness  
Acceptance Test: End-to-end BI runbook (`Tableau`/`Power BI`/`Excel`/connectivity tools) passes on CI, plus ODBC conformance suite and memory-leak/perf sanity checks  
Owner: Platform Lead + ODBC Team  
Risk: High  
ETA: 1 week

## .NET/JDBC Workstream

### DOTNET-101
Title: Implement async API semantics and cancellable operations  
Priority: P1  
Status: Partial  
Gap: Async and cancellation behavior is incomplete for production workloads  
Acceptance Test: Cancellation during long-running query must abort command and release connection without deadlocks  
Owner: .NET Team  
Risk: High  
ETA: 2–3 weeks

### DOTNET-102
Title: Enterprise connection pooling and reconnection resilience  
Priority: P0  
Status: Partial  
Gap: Pooling, reconnect, and circuit-breaker behavior inconsistent  
Acceptance Test: Soak test with pool saturation, transient failures, and failover; no pool corruption and bounded connection leak rate  
Owner: .NET Team  
Risk: High  
ETA: 3–5 weeks

### DOTNET-103
Title: Transaction semantics parity: isolation + savepoints + nested flows  
Priority: P0  
Status: Partial  
Gap: Isolation level correctness and savepoint handling are incomplete  
Acceptance Test: Isolation matrix and savepoint rollback matrix across concurrent writers  
Owner: .NET Team + QA  
Risk: High  
ETA: 4–6 weeks

### DOTNET-104
Title: Finish prepared statement cache and metadata/Lob pathways  
Priority: P1  
Status: Partial  
Gap: Metadata retrieval, prepared-statement lifecycle, and LOB streaming gaps  
Acceptance Test: Metadata reflectivity tests plus prepared cache hit-rate and stale-plan invalidation; LOB stream roundtrip  
Owner: .NET Team  
Risk: High  
ETA: 3–5 weeks

### JDBC-201
Title: Deliver JDBC async/reactive pathway and cancellation behavior  
Priority: P1  
Status: Partial  
Gap: No robust reactive and cancellation coverage for enterprise app stacks  
Acceptance Test: Non-blocking query cancellation and reactive timeout handling under thread/contention stress  
Owner: JDBC Team  
Risk: High  
ETA: 3–5 weeks

### JDBC-202
Title: Complete JDBC metadata and protocol feature parity  
Priority: P0  
Status: Partial  
Gap: Missing transaction and metadata parity, plus prepared/LOB behavior for enterprise clients  
Acceptance Test: JDBC conformance suite with metadata accuracy, prepared-statement lifecycle, and `ResultSet`/`DatabaseMetaData` behavior checks  
Owner: JDBC Team + QA  
Risk: High  
ETA: 4–6 weeks

### JDBC-203
Title: Add .NET/JDBC cross-runtime pooling contract test as release gate  
Priority: P0  
Status: Not yet defined  
Gap: Inconsistent behavior across managed drivers  
Acceptance Test: Common pooling/error-recovery contract suite passes in CI with benchmarked baseline  
Owner: Core Runtime + JVM/Platform Team  
Risk: High  
ETA: 1 week (post JDBC-201 to JDBC-202 and DOTNET-101 to DOTNET-104)

## Platform Workstream

### PLATFORM-301
Title: Kubernetes packaging and sidecar connectivity story  
Priority: P1  
Status: Missing  
Gap: No official cloud-native deployment pattern  
Acceptance Test: Helm chart deploy and sidecar path verified in CI on local Kubernetes cluster  
Owner: Platform Engineering  
Risk: High  
ETA: 2–4 weeks

### PLATFORM-302
Title: TLS + cert rotation playbook for managed/listener modes  
Priority: P0  
Status: Partial  
Gap: No clear cert-rotation and secret-update story  
Acceptance Test: Rotate certificate secret while service stays online; active sessions reconnect cleanly  
Owner: Security + Platform Engineering  
Risk: High  
ETA: 2–3 weeks

### PLATFORM-303
Title: Standardize secure secret integration patterns  
Priority: P1  
Status: Missing  
Gap: Incomplete secret/backend integration examples  
Acceptance Test: Docs and examples for short-lived credentials, rotation, and non-interactive startup via mounted secrets  
Owner: Platform Engineering  
Risk: Medium  
ETA: 2 weeks

### PLATFORM-304
Title: Cross-driver managed/listener behavior contract  
Priority: P0  
Status: Partial  
Gap: Connection/retry/cancel/reconnect semantics differ between drivers  
Acceptance Test: Golden integration matrix across all drivers for managed/listener handshake, reconnect, auth failure, and timeout handling  
Owner: Platform + Driver Lead  
Risk: High  
ETA: 2–4 weeks

## Ecosystem Workstream

### ECOSYS-401
Title: Prisma adapter integration  
Priority: P1  
Status: Missing  
Gap: No Prisma adapter  
Acceptance Test: CRUD/transaction/reflection tests in a Prisma sample app  
Owner: Ecosystem Team  
Risk: Medium  
ETA: 4–8 weeks

### ECOSYS-402
Title: Production-ready SQLAlchemy dialect  
Priority: P1  
Status: Missing  
Gap: No production-ready SQLAlchemy dialect package  
Acceptance Test: SQLAlchemy introspection and ORM session/transaction tests across model types  
Owner: Ecosystem Team  
Risk: Medium  
ETA: 4–8 weeks

### ECOSYS-403
Title: Hibernate dialect package  
Priority: P1  
Status: Missing  
Gap: No Hibernate integration package  
Acceptance Test: JPA bootstrapping plus entity lifecycle and migration-mapping tests in a sample service  
Owner: Ecosystem Team  
Risk: Medium  
ETA: 6–8 weeks

### ECOSYS-404
Title: TypeORM adapter  
Priority: P1  
Status: Missing  
Gap: No TypeORM driver/adapter  
Acceptance Test: TypeORM schema + CRUD + transaction tests in sample Node service  
Owner: Ecosystem Team  
Risk: Medium  
ETA: 4–8 weeks

### ECOSYS-405
Title: Native async consistency across languages  
Priority: P1  
Status: Incomplete  
Gap: Python asyncio and Go context cancellation are not fully standardized  
Acceptance Test: Async integration tests with cancellation/timeouts in both ecosystems and comparable API patterns across drivers  
Owner: Platform + Python/Go Drivers  
Risk: High  
ETA: 4–6 weeks

## Release Gate Policy (strict)

- Gate condition: release blocked until all P0 tickets in ODBC, .NET/JDBC, and Platform are complete and verified  
- Gate condition: each ticket acceptance test must pass in CI with artifacts preserved  
- Gate condition: ODBC enterprise acceptance run (`BI metadata + pooling + bulk + LOB`) must be green before enterprise release  
- Gate condition: .NET/JDBC cross-runtime contract suite must pass with no open regressions  
- Gate condition: platform deployment/security TLS scenario and Kubernetes sidecar path must pass before GA
