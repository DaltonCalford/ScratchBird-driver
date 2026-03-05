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
  - `Tests/ScratchBirdTests/IntegrationTests.swift:13-31` env-gated live handshake/connect/close coverage for direct and manager-proxy DSNs.
- Gaps/next actions:
  - Add failure-path live connection coverage (manager auth challenge failure, version/protocol mismatch, and socket-read teardown behavior).

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
  - `Tests/ScratchBirdTests/IntegrationTests.swift:48-60` env-gated live begin/commit/rollback/savepoint lifecycle.
- Gaps/next actions:
  - Add transaction-state behavior checks tied to server `READY`/txn-id transitions (unit coverage is payload/validation focused today).
  - Add explicit live failure semantics for nested/broken transaction flows with SQLSTATE assertions.

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
  - `Tests/ScratchBirdTests/IntegrationTests.swift:13-46` env-gated live simple and parameterized execution paths.
- Gaps/next actions:
  - Add live execution tests for cancellation timing and portal suspend/resume behavior.
  - Add explicit parity coverage for advanced execution surface area (batch/multi-result/generated-key semantics).

## META (`JDBCBL-META`)

- Current status: `Partial`
- Lane-local source anchors:
  - `Sources/ScratchBird/Metadata.swift:11-35` catalog query constants.
  - `Sources/ScratchBird/Metadata.swift:37-323` metadata-only recursive schema tree shaping plus schema-name extraction (`metadataSchemaNames`, `metadataSchemaPathsForNavigation`, `buildMetadataSchemaTree`, `buildMetadataSchemaTreeRows`) with optional parent expansion and per-parent uniqueness.
  - `Sources/ScratchBird/Connection.swift:140-191` client-facing metadata query wrappers (`metadataSchemas`, `metadataTables`, `metadataColumns`, `metadataIndexes`, `metadataIndexColumns`, `metadataConstraints`, `metadataProcedures`, `metadataFunctions`) and schema-tree accessors (`metadataSchemaTree`, `metadataSchemaTreeRows`).
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/MetadataRecursiveSchemaTests.swift:13-45` schema-name extraction/normalization paths (named-column and fallback-column modes).
  - `Tests/ScratchBirdTests/MetadataRecursiveSchemaTests.swift:47-62` database/default root row + top-branch metadata row shape.
  - `Tests/ScratchBirdTests/MetadataRecursiveSchemaTests.swift:64-74` dotted parent expansion behavior for schema navigation paths.
  - `Tests/ScratchBirdTests/MetadataRecursiveSchemaTests.swift:76-88` uniqueness within the same parent branch.
  - `Tests/ScratchBirdTests/MetadataRecursiveSchemaTests.swift:90-104` same leaf name preserved under different parents.
  - `Tests/ScratchBirdTests/IntegrationTests.swift:62-76` env-gated live metadata wrapper invocation + schema tree row shaping.
- Gaps/next actions:
  - Expand live metadata integration coverage to validate full catalog payload completeness (keys/privileges/types/DDL-editor families), not only schemas/tables/tree entry points.

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
  - `Tests/ScratchBirdTests/IntegrationTests.swift:78-132` env-gated live SQLSTATE propagation for execution failures plus optional bad-auth connect mapping (`SCRATCHBIRD_TEST_BAD_AUTH_DSN`).
- Gaps/next actions:
  - Expand live auth/connect `.error` propagation to include manager auth failures and explicit read-loop teardown paths.

## RES (`JDBCBL-RES`)

- Current status: `Partial`
- Lane-local source anchors:
  - `Sources/ScratchBird/CircuitBreaker.swift:11-116`
  - `Sources/ScratchBird/Keepalive.swift:11-153` keepalive tracker/manager plus validation stats (`KeepaliveManager.Stats`).
  - `Sources/ScratchBird/Telemetry.swift:11-108`
  - `Sources/ScratchBird/LeakDetector.swift:11-110` leak detector timer/guard plus leak stats (`LeakDetector.Stats`).
  - `Sources/ScratchBird/Pool.swift:11-118` bounded connection-pool checkout/release and `withConnection` churn surface.
  - `Sources/ScratchBird/Config.swift:140-293` DSN-configurable keepalive/leak tuning options.
  - `Sources/ScratchBird/Connection.swift:71-103` resilience component initialization from config.
  - `Sources/ScratchBird/Connection.swift:211-224` internal resilience debug snapshot (`debugResilienceStats`).
  - `Sources/ScratchBird/Connection.swift:554-616` operation-level idle validation and keepalive activity updates.
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:55-99` deterministic circuit-breaker closed/open/half-open transition and reopen-on-failure behavior.
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:102-140` keepalive idle-threshold checks plus manager-driven ping verification.
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:142-170` leak detector guard idempotency and checkout metadata/stack capture.
  - `Tests/ScratchBirdTests/ErrorResilienceTests.swift:172-203` telemetry tracing-disabled gate, success/failure metrics accounting, SQL sanitization.
  - `Tests/ScratchBirdTests/ConfigTests.swift:41-54` resilience DSN option parsing.
  - `Tests/ScratchBirdTests/IntegrationTests.swift:131-250` env-gated live keepalive/leak assertions for single-connection and concurrent multi-connection workloads, plus pool checkout/release churn and exhaustion behavior.
- Gaps/next actions:
  - Expand pool behavior to include wait-queue/timeouts and explicit failure-recovery semantics under sustained saturation/fault injection.
