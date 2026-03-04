# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope

- Lane-local S0 artifact for `tracks/beta/drivers/dart` only.
- Mapping is based only on source and tests in this lane.
- This file does not declare cross-lane or canonical spec authority.

## CONN (JDBCBL)

- Current status: Implemented
- Lane-local source anchors:
  - `lib/src/config.dart:68-191` (`ScratchBirdConfig.fromDsn`, URI/KV parsing).
  - `lib/src/config.dart:193-220` protocol and `front_door_mode` normalization/validation.
  - `lib/src/client.dart:106-157` primary connect flow (`connect`, `_connect`, `_handshake`, resilience start).
  - `lib/src/client.dart:190-292` manager proxy handshake/auth/connect path.
  - `lib/src/client.dart:294-297` close path.
- Lane-local test anchors:
  - `test/config_test.dart:13-37` DSN parsing, manager proxy parameters, invalid front-door validation.
  - `test/connect_validation_test.dart:24-63` connect-time policy rejection coverage (`sslmode=disable`, `binary_transfer=false`, `compression=zstd`).
  - `test/integration_test.dart:25-39` live direct connect/query smoke coverage (gated by `SCRATCHBIRD_TEST_DSN`).
- Gaps/next actions:
  - Add manager-proxy integration coverage for `_performManagerConnect` and manager handshake/auth failure paths.

## TXN (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/protocol.dart:94-104` isolation and transaction option flags.
  - `lib/src/protocol.dart:324-364` TXN payload builders (`begin`, `commit`, `rollback`, savepoint operations).
  - `lib/src/client.dart:330-408` client TXN APIs with active/inactive transaction guardrails.
  - `lib/src/client.dart:646-670` async `txnStatus` handling updates local transaction id state.
  - `lib/src/client.dart:778-824` ready-state txn tracking and TXN guard helper methods.
- Lane-local test anchors:
  - `test/txn_exec_parity_test.dart:19-60` TXN guardrail checks (`commit`/`rollback`/`savepoint` require active transaction).
  - `test/txn_exec_parity_test.dart:63-101` TXN payload encoding coverage for begin and savepoint/release/rollback-to payloads.
  - `test/integration_test.dart:76-89` live begin/commit/rollback cycle coverage (gated by `SCRATCHBIRD_TEST_DSN`).
- Gaps/next actions:
  - Add live integration tests for savepoint/release/rollback-to flows and server-side TXN failure paths.
  - Add nested-begin rejection coverage against a real server.

## EXEC (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/client.dart:308-320` `query` entrypoint with SQL-empty guard.
  - `lib/src/client.dart:494-500` `cancel` rejects when no active in-flight sequence is tracked.
  - `lib/src/client.dart:573-644` result collection and send paths with pagination resume and query-sequence reset on terminal outcomes.
  - `lib/src/client.dart:460-468` SBLR execution path.
  - `lib/src/protocol.dart:199-302` query/parse/bind/execute/SBLR payload builders.
- Lane-local test anchors:
  - `test/txn_exec_parity_test.dart:104-131` EXEC guardrail checks (`query` empty SQL rejection, cancel-without-inflight rejection).
  - `test/txn_exec_parity_test.dart:134-171` EXEC payload encoding coverage for query/execute/cancel payload contracts.
  - `test/integration_test.dart:25-55` live simple and parameterized query coverage (gated by `SCRATCHBIRD_TEST_DSN`).
- Gaps/next actions:
  - Add integration tests for pagination (`portalSuspended` path) and SBLR execution.
  - Add focused execution tests for async message capture paths (`queryPlan`, `notification`, `sblrCompiled`) under live wire flow.

## META (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/metadata.dart:9-31` catalog query constants (schemas/tables/columns/indexes/constraints/procedures/functions).
  - `lib/src/metadata.dart:33-135` metadata collection normalization + query resolution helpers.
  - `lib/src/metadata.dart:137-215` metadata-only recursive schema tree shaping (`expandParents`, database root, per-parent uniqueness).
  - `lib/src/metadata.dart:217-360` metadata row shaping with optional dotted-parent expansion and catalog-preserving synthetic parent rows.
  - `lib/src/client.dart:329-354` `queryMetadata`, `getSchema`, and `getSchemaTree` client metadata APIs.
  - `lib/scratchbird.dart:14` metadata export.
- Lane-local test anchors:
  - `test/metadata_execution_test.dart:28-107` metadata query alias resolution and runtime schema expansion/tree APIs.
  - `test/metadata_recursive_schema_test.dart:6-33` database->default-branch style metadata rows and dotted parent expansion behavior.
  - `test/metadata_recursive_schema_test.dart:35-58` dotted schema parent expansion ordering/uniqueness in path extraction.
  - `test/metadata_recursive_schema_test.dart:60-79` per-parent uniqueness for duplicate leaf paths.
  - `test/metadata_recursive_schema_test.dart:81-107` same leaf name under different parents remains distinct in recursive schema tree.
  - `test/integration_test.dart:92-110` live metadata wrapper execution coverage (gated by `SCRATCHBIRD_TEST_DSN`).
- Gaps/next actions:
  - Add live metadata integration coverage for restrictions/wildcards and DDL-editor payload fields.

## TYPE (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/types.dart:14-49` OID/type constants.
  - `lib/src/types.dart:143-377` parameter encoding and value decoding core logic.
  - `lib/src/types.dart:413-670` range/composite encode/decode handling.
  - `lib/src/types.dart:672-760` unknown-binary/text coercion and array literal parsing.
- Lane-local test anchors:
  - `test/type_mapping_test.dart:38-101` array/vector/range/composite/inet-cidr-macaddr round-trip coverage.
  - `test/type_mapping_test.dart:103-230` scalar decode coverage, text-vs-unknown decode behavior, and negative-path range/composite/unsupported-type checks.
  - `test/integration_test.dart:57-74` live scalar type round-trip smoke coverage (gated by `SCRATCHBIRD_TEST_DSN`).
- Gaps/next actions:
  - Add live integration tests validating binary wire round-trip behavior for complex types (json/jsonb/range/composite/vector/inet-cidr-macaddr).

## ERR (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/protocol.dart:159-176` header validation exceptions.
  - `lib/src/client.dart:117-126` connect-time option rejection exceptions.
  - `lib/src/client.dart:219-291` manager protocol validation/auth/connect exceptions.
  - `lib/src/client.dart:521-523`, `559-560`, `719-720` generic auth/query/describe error handling.
  - `lib/src/protocol.dart:59` `MessageType.error` constant.
- Lane-local test anchors:
  - `test/error_resilience_test.dart:24-58` protocol framing error-path tests (`decodeHeader` invalid length/magic/version/max payload).
- Gaps/next actions:
  - Parse and expose structured server error payload fields instead of only generic `Exception` messages.
  - Introduce typed driver exception classes and map server SQLSTATE/class data into driver errors.

## RES (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/circuit_breaker.dart:9-114` circuit-breaker implementation.
  - `lib/src/keepalive.dart:11-87` idle validation and periodic ping orchestration.
  - `lib/src/leak_detector.dart:11-82` connection leak tracking/guarding.
  - `lib/src/telemetry.dart:11-101` tracing/metrics/slow-query collection.
  - `lib/src/client.dart:832-891` resilience integration (`_startResilience`, `_stopResilience`, `_withResilience`).
- Lane-local test anchors:
  - `test/error_resilience_test.dart:61-112` circuit-breaker transition and recovery tests.
  - `test/error_resilience_test.dart:114-153` keepalive tracker/manager validation and ping trigger tests.
  - `test/error_resilience_test.dart:155-180` leak detector guard release + stack-capture behavior tests.
  - `test/error_resilience_test.dart:182-214` telemetry tracing/metrics/sanitization coverage.
- Gaps/next actions:
  - Add integration tests covering idle-validation ping against live sockets and resilience state cleanup on client close.
  - Add deterministic tests for timer-driven leak reports and slow-query log retention boundaries.
