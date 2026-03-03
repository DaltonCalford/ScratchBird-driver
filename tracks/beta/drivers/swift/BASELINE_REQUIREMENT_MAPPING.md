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
  - `Tests/ScratchBirdTests/TypeMappingTests.swift:5-74`
- Gaps/next actions:
  - Expand lane tests to cover additional scalar/date-time/JSON paths and negative encode/decode cases.

## ERR (`JDBCBL-ERR`)

- Current status: `Partial`
- Lane-local source anchors:
  - `Sources/ScratchBird/Protocol.swift:11-15`
  - `Sources/ScratchBird/Protocol.swift:166-180`
  - `Sources/ScratchBird/Config.swift:11-57`
  - `Sources/ScratchBird/Connection.swift:91-99`
  - `Sources/ScratchBird/Connection.swift:376`
  - `Sources/ScratchBird/Connection.swift:404`
  - `Sources/ScratchBird/Connection.swift:657-667`
  - `Sources/ScratchBird/Connection.swift:675-763`
  - `Sources/ScratchBird/Socket.swift:157-178`
  - `Sources/ScratchBird/Socket.swift:289-304`
  - `Sources/ScratchBird/Socket.swift:338`
- Lane-local test anchors:
  - `Tests/ScratchBirdTests/ConfigTests.swift:51-99`
- Gaps/next actions:
  - Add tests for wire-level `.error` responses and standardize error typing beyond generic `NSError`.

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
  - None in `Tests/ScratchBirdTests`.
- Gaps/next actions:
  - Add deterministic tests for circuit-breaker transitions, keepalive validation, and leak-check lifecycle behavior.
