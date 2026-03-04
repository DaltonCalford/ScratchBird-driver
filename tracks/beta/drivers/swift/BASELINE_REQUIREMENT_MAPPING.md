# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope

- Lane-local S0 artifact for `tracks/beta/drivers/swift` only.
- Maps Swift lane capability areas to JDBCBL groups using evidence in this lane's source and tests.
- Not a cross-lane conformance statement.

## CONN (`JDBCBL-CONN`)

- Current status: `Implemented`
- Lane-local source anchors:
  - `Sources/ScratchBird/Config.swift:11-57`
  - `Sources/ScratchBird/Config.swift:195-263`
  - `Sources/ScratchBird/Connection.swift:84-119`
  - `Sources/ScratchBird/Connection.swift:332-381`
  - `Sources/ScratchBird/Connection.swift:672-765`
  - `Sources/ScratchBird/Socket.swift:136-179`
  - `Sources/ScratchBird/Socket.swift:287-415`
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/ConfigTests.swift:13-48`
  - `Tests/ScratchBirdTests/ConfigTests.swift:51-99`
- Gaps/next actions:
  - Add live connection tests that assert successful handshake and close paths (current tests focus on parsing and connect-time guardrails).

## TXN (`JDBCBL-TXN`)

- Current status: `Partial`
- Lane-local source anchors:
  - `Sources/ScratchBird/Protocol.swift:38-43`
  - `Sources/ScratchBird/Protocol.swift:116-126`
  - `Sources/ScratchBird/Protocol.swift:325-369`
  - `Sources/ScratchBird/TxnExecValidation.swift:11-49`
  - `Sources/ScratchBird/Connection.swift:152-238`
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/TxnExecParityTests.swift:13-47`
  - `Tests/ScratchBirdTests/TxnExecParityTests.swift:62-93`
- Gaps/next actions:
  - Add live wire/integration transaction tests for begin/commit/rollback/savepoint success and failure semantics.
  - Add transaction-state behavior checks tied to server `READY`/txn-id transitions (unit coverage is payload/validation focused today).

## EXEC (`JDBCBL-EXEC`)

- Current status: `Partial`
- Lane-local source anchors:
  - `Sources/ScratchBird/Connection.swift:127-137`
  - `Sources/ScratchBird/Connection.swift:284-295`
  - `Sources/ScratchBird/Connection.swift:333-339`
  - `Sources/ScratchBird/Connection.swift:392-449`
  - `Sources/ScratchBird/Protocol.swift:266-280`
  - `Sources/ScratchBird/TxnExecValidation.swift:51-70`
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/TxnExecParityTests.swift:50-60`
  - `Tests/ScratchBirdTests/TxnExecParityTests.swift:95-104`
- Gaps/next actions:
  - Add live execution tests for simple queries, parameterized queries, cancellation timing, and portal suspend/resume behavior.
  - Add explicit parity coverage for advanced execution surface area (batch/multi-result/generated-key semantics).

## META (`JDBCBL-META`)

- Current status: `Partial`
- Lane-local source anchors:
  - `Sources/ScratchBird/Metadata.swift:11-35` catalog query constants.
  - `Sources/ScratchBird/Metadata.swift:37-244` metadata-only recursive schema tree shaping (`metadataSchemaPathsForNavigation`, `buildMetadataSchemaTree`, `buildMetadataSchemaTreeRows`) with optional parent expansion and per-parent uniqueness.
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/MetadataRecursiveSchemaTests.swift:13-28` database/default root row + top-branch metadata row shape.
  - `Tests/ScratchBirdTests/MetadataRecursiveSchemaTests.swift:30-40` dotted parent expansion behavior for schema navigation paths.
  - `Tests/ScratchBirdTests/MetadataRecursiveSchemaTests.swift:42-54` uniqueness within the same parent branch.
  - `Tests/ScratchBirdTests/MetadataRecursiveSchemaTests.swift:56-70` same leaf name preserved under different parents.
- Gaps/next actions:
  - Wire recursive schema shaping helpers through client-facing metadata execution APIs (metadata collection query wrappers and schema-tree accessors).
  - Add live metadata integration coverage validating engine-backed metadata payload completeness beyond schema-tree shaping.

## TYPE (`JDBCBL-TYPE`)

- Current status: `Partial`
- Lane-local source anchors:
  - `Sources/ScratchBird/Types.swift:11-214`
  - `Sources/ScratchBird/Types.swift:216-289`
  - `Sources/ScratchBird/Types.swift:391-844`
  - `Sources/ScratchBird/Connection.swift:398`
  - `Sources/ScratchBird/Connection.swift:425-427`
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/TypeMappingTests.swift:5-180`
- Gaps/next actions:
  - Add live integration codec coverage (wire roundtrip against engine fixtures for scalar, temporal, JSON, and advanced container types).

## ERR (`JDBCBL-ERR`)

- Current status: `Partial`
- Lane-local source anchors:
  - `Sources/ScratchBird/Protocol.swift:11-28`
  - `Sources/ScratchBird/Protocol.swift:197-300` (`parseErrorMessage`, `buildScratchBirdError`, `buildScratchBirdNSError`, structured SQLSTATE/detail/hint extraction).
  - `Sources/ScratchBird/Errors.swift:11-289` typed driver exception hierarchy and SQLSTATE exact/class mappers.
  - `Sources/ScratchBird/Config.swift:11-57`
  - `Sources/ScratchBird/Connection.swift:91-99`
  - `Sources/ScratchBird/Connection.swift:265-269` ping `.error` mapped with connection SQLSTATE default.
  - `Sources/ScratchBird/Connection.swift:389-393` auth `.error` mapped with authorization SQLSTATE default.
  - `Sources/ScratchBird/Connection.swift:423-427` query `.error` mapped with execution SQLSTATE default.
  - `Sources/ScratchBird/Connection.swift:802-806` drain/request `.error` mapped with execution SQLSTATE default.
  - `Sources/ScratchBird/Connection.swift:657-667`
  - `Sources/ScratchBird/Connection.swift:675-763`
  - `Sources/ScratchBird/Socket.swift:157-178`
  - `Sources/ScratchBird/Socket.swift:289-304`
  - `Sources/ScratchBird/Socket.swift:338`
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/ConfigTests.swift:51-99`
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:13-53` protocol header decode guardrails (`invalidHeader`, `unsupportedVersion`, `payloadTooLarge`).
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:55-154` wire-error payload parsing, typed SQLSTATE mapping, structured SQLSTATE/detail/hint propagation, and malformed-payload fallback assertions.
- Gaps/next actions:
  - Add integration tests that validate `.error` propagation across live socket reads in end-to-end query/auth flows.

## RES (`JDBCBL-RES`)

- Current status: `Partial`
- Lane-local source anchors:
  - `Sources/ScratchBird/CircuitBreaker.swift:11-116`
  - `Sources/ScratchBird/Keepalive.swift:11-112`
  - `Sources/ScratchBird/Telemetry.swift:11-108`
  - `Sources/ScratchBird/LeakDetector.swift:11-96`
  - `Sources/ScratchBird/Connection.swift:466-528`
  - `Sources/ScratchBird/Connection.swift:122-125`
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:55-99` deterministic circuit-breaker closed/open/half-open transition and reopen-on-failure behavior.
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:102-140` keepalive idle-threshold checks plus manager-driven ping verification.
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:142-170` leak detector guard idempotency and checkout metadata/stack capture.
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:172-203` telemetry tracing-disabled gate, success/failure metrics accounting, SQL sanitization.
- Gaps/next actions:
  - Add live integration coverage for keepalive timeout behavior and leak warnings under real pooled connection workloads.
