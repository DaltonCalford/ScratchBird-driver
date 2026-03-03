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
- Gaps/next actions:
  - Add connection integration tests for direct and manager-proxy paths (`_connect`, `_performManagerConnect`, `_handshake`).
  - Add tests for rejected options in connect validation (`sslmode=disable`, `binary_transfer=false`, `compression=zstd` at `lib/src/client.dart:118-126`).

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
- Gaps/next actions:
  - Add live integration tests for begin/commit/rollback/savepoint flows and server-side TXN failure paths.
  - Add coverage for nested-begin rejection and active-transaction commit/rollback success paths against a real server.

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
- Gaps/next actions:
  - Add integration tests for simple query, parameterized query, pagination (`portalSuspended` path), and SBLR execution.
  - Add focused execution tests for async message capture paths (`queryPlan`, `notification`, `sblrCompiled`) under live wire flow.

## META (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/metadata.dart:9-31` catalog query constants (schemas/tables/columns/indexes/constraints/procedures/functions).
  - `lib/src/metadata.dart:33-135` metadata collection normalization + query resolution helpers.
  - `lib/src/metadata.dart:137-215` metadata-only recursive schema tree shaping (`expandParents`, database root, per-parent uniqueness).
  - `lib/src/metadata.dart:217-360` metadata row shaping with optional dotted-parent expansion and catalog-preserving synthetic parent rows.
  - `lib/scratchbird.dart:14` metadata export.
- Lane-local test anchors:
  - `test/metadata_recursive_schema_test.dart:6-33` database->default-branch style metadata rows and dotted parent expansion behavior.
  - `test/metadata_recursive_schema_test.dart:35-58` dotted schema parent expansion ordering/uniqueness in path extraction.
  - `test/metadata_recursive_schema_test.dart:60-79` per-parent uniqueness for duplicate leaf paths.
  - `test/metadata_recursive_schema_test.dart:81-107` same leaf name under different parents remains distinct in recursive schema tree.
- Gaps/next actions:
  - Wire metadata shaping helpers through client-facing metadata execution APIs (for example `getSchema`/`getSchemaTree`) with runtime-configurable parent-expansion mode.
  - Add live metadata integration tests validating engine-backed metadata query execution and DDL-editor payload fields.

## TYPE (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/types.dart:14-49` OID/type constants.
  - `lib/src/types.dart:143-377` parameter encoding and value decoding core logic.
  - `lib/src/types.dart:413-670` range/composite encode/decode handling.
  - `lib/src/types.dart:672-760` unknown-binary/text coercion and array literal parsing.
- Lane-local test anchors:
  - `test/type_mapping_test.dart:5-68` array/vector/range/composite/inet-cidr-macaddr round-trip coverage.
- Gaps/next actions:
  - Add tests for scalar decode paths (bool/int/date/time/uuid/json/jsonb) and binary/text mode cross-checks.
  - Add negative-path tests for unsupported encodings and range-bound inference errors.

## ERR (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/protocol.dart:159-176` header validation exceptions.
  - `lib/src/client.dart:117-126` connect-time option rejection exceptions.
  - `lib/src/client.dart:219-291` manager protocol validation/auth/connect exceptions.
  - `lib/src/client.dart:521-523`, `559-560`, `719-720` generic auth/query/describe error handling.
  - `lib/src/protocol.dart:59` `MessageType.error` constant.
- Lane-local test anchors:
  - None in `test/`.
- Gaps/next actions:
  - Parse and expose structured server error payload fields instead of only generic `Exception` messages.
  - Introduce typed driver exception classes and add focused error-path tests.

## RES (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
  - `lib/src/circuit_breaker.dart:9-114` circuit-breaker implementation.
  - `lib/src/keepalive.dart:11-87` idle validation and periodic ping orchestration.
  - `lib/src/leak_detector.dart:11-82` connection leak tracking/guarding.
  - `lib/src/telemetry.dart:11-101` tracing/metrics/slow-query collection.
  - `lib/src/client.dart:832-891` resilience integration (`_startResilience`, `_stopResilience`, `_withResilience`).
- Lane-local test anchors:
  - None in `test/`.
- Gaps/next actions:
  - Add deterministic unit tests for circuit/keepalive/leak/telemetry behaviors.
  - Add integration tests covering idle validation ping, circuit-open rejection, and resilience state cleanup on close.
