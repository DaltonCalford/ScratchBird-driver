# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope

- Lane-local S0 artifact only for `tracks/alpha/drivers/mojo`.
- Evidence is restricted to files in this lane; no cross-lane claims are made.

## CONN (JDBCBL)

- Current status: Implemented (bridge lane) + Native bootstrap scaffolding
- Lane-local source anchors:
- `src/scratchbird.mojo:497` (`ScratchBirdConfig` DSN/config handling)
- `src/scratchbird.mojo:1244` (`ScratchBirdConnection` construction and connection bootstrap)
- `src/scratchbird.mojo:1264` (`_connect` TLS socket setup and connect-time validation)
- `src/scratchbird.py:659` (bridge-shim connect guard enforcement for TLS/binary/compression/mode/auth-failure simulation)
- `src/scratchbird_native.mojo:23` (native-bootstrap `ScratchBirdConfig`/guard parser path in current Mojo syntax)
- `src/scratchbird_native.mojo:503` (native-bootstrap `connect` entrypoint)
- `src/scratchbird_native.mojo:158` (native-bootstrap `ping` surface)
- `src/scratchbird_native.mojo:73` (native-bootstrap `query_with_params` with placeholder counting and `07001` mismatch semantics)
- `src/scratchbird.mojo:1304` (`_startup_and_auth` startup/auth exchange)
- `src/scratchbird.mojo:1390` (`_perform_manager_connect` manager-proxy connect path)
- `src/scratchbird.mojo:1641` (`ping`)
- `src/scratchbird.mojo:1481` (`close`)
- Lane-local test anchors:
- `tests/integration.mojo:19`
- `tests/sbdriver_conformance.mojo:157`
- `tests/connection_guards.py:26`
- `tests/connection_guards.py:54` (`front_door_mode` validation guard)
- `tests/connection_guards.py:58` (deterministic auth-failure guard with SQLSTATE `28P01`)
- `tests/integration.py:52` (integration launcher now runs native bootstrap smoke first with fallback controls)
- `tests/sbdriver_conformance.py:73` (conformance launcher now runs native bootstrap smoke first with fallback controls)
- `tests/sbdriver_conformance.py:37` (deterministic fallback DSN keeps conformance non-skipping by default)
- `tests/integration.py:53` (manager-proxy integration smoke branch)
- `tests/integration.py:59` (bad-auth integration smoke branch)
- `tests/native_bootstrap.mojo:60` (native bootstrap connect/ping/query smoke path via `mojo run -I src`)
- `tests/native_bootstrap.mojo:95` (native bootstrap prepare-bind + mismatch guard path)
- Gaps/next actions:
- Replace legacy `src/scratchbird.mojo` syntax/API surface with current Mojo-native transport implementation and retire bridge-first runtime path.
- Provide CI/dev environment DSNs so manager-proxy and bad-auth integration branches execute against a running endpoint.

## TXN (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:1019` (`build_txn_begin_payload`)
- `src/scratchbird.mojo:1025` (`build_txn_commit_payload`)
- `src/scratchbird.mojo:1029` (`build_txn_rollback_payload`)
- `src/scratchbird.mojo:1635` (`begin` kwargs->flags/payload mapping)
- `src/scratchbird.mojo:1671` (`commit` no-op when no active txn)
- `src/scratchbird.mojo:1678` (`rollback` no-op when no active txn)
- `src/scratchbird.mojo:1703` (`_drain_until_ready` propagates protocol error details)
- `src/scratchbird.py:776` (bridge-shim nested-transaction guard rails)
- `src/scratchbird.py:795` (bridge-shim savepoint create guard/name generation)
- `src/scratchbird.py:805` (bridge-shim savepoint release guard + `3B001`)
- `src/scratchbird.py:817` (bridge-shim rollback-to-savepoint guard + stack trim)
- `src/scratchbird_native.mojo:81` (native-bootstrap `begin` nested-transaction guard `25001`)
- `src/scratchbird_native.mojo:87` (native-bootstrap `commit` no-op when no active txn)
- `src/scratchbird_native.mojo:93` (native-bootstrap `rollback` no-op when no active txn)
- `src/scratchbird_native.mojo:99` (native-bootstrap savepoint create guard/name generation)
- `src/scratchbird_native.mojo:109` (native-bootstrap savepoint release guard + `3B001`)
- `src/scratchbird_native.mojo:124` (native-bootstrap rollback-to-savepoint guard + stack trim)
- Lane-local test anchors:
- `tests/txn_exec_parity.mojo:55` (`begin` flag/payload mapping assertions)
- `tests/txn_exec_parity.py:95` (nested `begin()` rejection with SQLSTATE `25001`)
- `tests/txn_exec_parity.mojo:90` (inactive transaction commit/rollback no-op assertions)
- `tests/txn_exec_parity.mojo:98` (active transaction commit/rollback message assertions)
- `tests/txn_exec_parity.py:130` (savepoint message/payload parity assertions)
- `tests/txn_exec_parity.py:150` (savepoint guard SQLSTATE assertions `25000`/`HY000`/`3B001`)
- `tests/txn_exec_parity.py:211` (shim `ping` + transaction lifecycle helper assertions)
- `tests/txn_exec_parity.py:230` (shim savepoint lifecycle + rollback-trim assertions)
- `tests/native_bootstrap.mojo:69` (native-bootstrap nested `begin()` rejection with `25001`)
- `tests/native_bootstrap.mojo:65` (native-bootstrap inactive `commit`/`rollback` no-op assertions)
- `tests/native_bootstrap.mojo:75` (native-bootstrap savepoint lifecycle + `25000`/`3B001` guards)
- Gaps/next actions:
- Add live transaction integration coverage against a running ScratchBird endpoint.

## EXEC (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:1526` (`query` path selection for `params is None` vs parameterized execution)
- `src/scratchbird.mojo:1545` (`_extended_query` parse/bind/execute flow)
- `src/scratchbird.mojo:1584` (`_fetch_more`)
- `src/scratchbird.mojo:1590` (`_read_resultset`)
- `src/scratchbird.mojo:1542` (`stream`)
- `src/scratchbird.mojo:751` (`ScratchBirdStream`)
- `src/scratchbird.mojo:1632` (`prepare`)
- `src/scratchbird.mojo:810` (`ScratchBirdStatement.execute`)
- `src/scratchbird.mojo:1699` (`cancel`)
- `src/scratchbird.py:773` (bridge-shim `prepare` statement entrypoint)
- `src/scratchbird.py:719` (bridge-shim statement `execute` path through query bindings)
- `src/scratchbird.py:829` (bridge-shim `stream` entrypoint)
- `src/scratchbird.py:840` (bridge-shim `cancel` signal path)
- `src/scratchbird.py:854` (bridge-shim stream iterator with `57014` cancellation behavior)
- `src/scratchbird_native.mojo:73` (native-bootstrap `query_with_params` with placeholder counting + `07001` mismatch)
- `src/scratchbird_native.mojo:77` (native-bootstrap `prepare` statement scaffold)
- `src/scratchbird_native.mojo:199` (native-bootstrap prepared `execute` path)
- `src/scratchbird_native.mojo:138` (native-bootstrap `stream` lifecycle entrypoint)
- `src/scratchbird_native.mojo:150` (native-bootstrap `cancel` signal path)
- `src/scratchbird_native.mojo:177` (native-bootstrap stream iterator with `57014` cancellation behavior)
- `src/scratchbird_native.mojo:273` (native-bootstrap query rowcount semantics for paging/metadata queries)
- `src/scratchbird_native.mojo:73` (native-bootstrap operation-level cancel reset before query/stream paths)
- Lane-local test anchors:
- `tests/txn_exec_parity.mojo:108` (`query(..., None)` simple-query path assertion)
- `tests/txn_exec_parity.mojo:117` (`query(..., [])` extended-query path assertion)
- `tests/txn_exec_parity.py:196` (shim prepared execute + `07001` mismatch assertions)
- `tests/txn_exec_parity.py:263` (stream fetch-boundary assertions)
- `tests/txn_exec_parity.py:279` (cancelled stream returns SQLSTATE `57014`)
- `tests/txn_exec_parity.py:298` (post-cancel stream recovery assertions)
- `tests/sbdriver_conformance.py:198` (manifest `requires` gating for prepare/cancel capabilities)
- `tests/sbdriver_conformance.py:417` (fallback DSN defaulting + explicit skip mode when fallback disabled)
- `tests/sbdriver_conformance.py:305` (prepare-bind and cancel manifest paths enabled by default)
- `tests/sbdriver_conformance.py:233` (manifest `expect_sqlstate` matching)
- `tests/integration.mojo:22`
- `tests/sbdriver_conformance.mojo:161`
- `tests/sbdriver_conformance.mojo:174`
- `tests/sbdriver_conformance.mojo:190`
- `tests/native_bootstrap.mojo:95` (native-bootstrap prepare-bind + mismatch assertions)
- `tests/native_bootstrap.mojo:100` (native-bootstrap prepared execute parity assertions)
- `tests/native_bootstrap.mojo:64` (native-bootstrap paging query rowcount assertion)
- `tests/native_bootstrap.mojo:164` (native-bootstrap stream/cancel `57014` assertions)
- `tests/native_bootstrap.mojo:168` (native-bootstrap post-cancel stream recovery assertion)
- `tests/README.md:10`
- Gaps/next actions:
- Add live assertions for streamed fetch boundaries and cancel behavior against long-running statements.

## META (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:1725` (metadata SQL constants now include extended families: catalogs, primary/foreign keys, table/column privileges, type info, routines)
- `src/scratchbird.mojo:1760` (`METADATA_COLLECTION_QUERY_MAP` / `METADATA_COLLECTION_ALIASES`)
- `src/scratchbird.mojo:1542` (`query_metadata` executable metadata routing through normal query path)
- `src/scratchbird.mojo:1547` (`get_schema` metadata row materialization surface)
- `src/scratchbird.mojo:1868` (`normalize_metadata_collection_name` / `resolve_metadata_collection_query`)
- `src/scratchbird.mojo:1778` (`schema_paths_for_navigation` with optional dotted parent expansion)
- `src/scratchbird.mojo:1799` (`build_schema_tree` recursive tree shaping with per-parent uniqueness)
- `src/scratchbird.mojo:1822` (`expand_schema_metadata_rows` synthetic ancestor row shaping)
- `src/scratchbird.mojo:1848` (`build_database_default_metadata_rows` database/default branch-style metadata rows)
- `src/scratchbird.py:760` (bridge-shim `query_metadata_rows` executable rowcount helper)
- `src/scratchbird_native.mojo:166` (native-bootstrap `query_metadata_rows` executable rowcount helper)
- `src/scratchbird_native.mojo:437` (native-bootstrap metadata collection alias normalization)
- `src/scratchbird_native.mojo:450` (native-bootstrap metadata query resolution)
- Lane-local test anchors:
- `tests/metadata_recursive_schema.mojo:24` (database/default branch style row shaping)
- `tests/metadata_recursive_schema.mojo:54` (dotted parent expansion ordering/uniqueness)
- `tests/metadata_recursive_schema.mojo:77` (per-parent uniqueness)
- `tests/metadata_recursive_schema.mojo:94` (same leaf name under different parents)
- `tests/metadata_execution.mojo:16` (metadata execution wrapper entrypoint)
- `tests/metadata_execution.py:38` (collection alias normalization coverage)
- `tests/metadata_execution.py:53` (extended collection query resolution coverage)
- `tests/metadata_execution.py:80` (metadata execution routing path coverage)
- `tests/metadata_execution.py:113` (metadata execution rowcount helper coverage)
- `tests/metadata_execution.py:111` (unsupported metadata collection `0A000` behavior)
- `tests/native_bootstrap.mojo:133` (native-bootstrap metadata executable rowcount smoke assertions)
- `tests/README.md:41` (metadata recursive schema scaffold invocation)
- Gaps/next actions:
- Add live metadata integration assertions for schema/table/column result stability against a running ScratchBird endpoint.
- Expand restriction-aware metadata filtering and payload-shaping assertions for DDL-editor-specific field contracts.

## TYPE (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:24` (OID constants used by type codec paths)
- `src/scratchbird.mojo:300` (`decode_value`)
- `src/scratchbird.mojo:368` (`encode_value`)
- `src/scratchbird.mojo:244` (`_parse_array_literal`)
- `src/scratchbird.mojo:262` (`_parse_vector_literal`)
- `src/scratchbird.mojo:279` (`_parse_range_literal`)
- `src/scratchbird.py:415` (bridge-shim OID-to-network mapping and fallback raw-wrapper path)
- `src/scratchbird.py:314` (bridge-shim array/vector/range parser utilities with quote-aware splitting)
- `src/scratchbird.py:534` (bridge-shim encode/decode helpers with truncation guard, temporal/json/uuid wrappers, and array-of-composite handling)
- Lane-local test anchors:
- `tests/integration.mojo:26`
- `tests/sbdriver_conformance.mojo:182`
- `tests/type_codecs.py:18` (array/range/vector/composite parsing and decode/encode assertions)
- `tests/type_codecs.py:53` (geometry + inet/cidr/macaddr decode assertions)
- `tests/type_codecs.py:75` (json/jsonb/uuid decode assertions)
- `tests/type_codecs.py:94` (date/time/timestamp/timestamptz/interval decode assertions)
- `tests/type_codecs.py:125` (int/text/record array decode assertions including array-of-composite)
- `tests/type_codecs.py:138` (unknown-OID fallback + `OID_INT4` truncation behavior)
- Gaps/next actions:
- Align bridge-shim temporal/json/uuid and array-of-composite codec semantics with native binary wire-format behavior once native Mojo transport is active.

## ERR (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:139` (`ScratchBirdError` with `sqlstate`, `detail`, `hint`)
- `src/scratchbird.py:233` (bridge-shim `ScratchBirdError` now carries `sqlstate/detail/hint`)
- `src/scratchbird.mojo:1127` (`parse_error_message`)
- `src/scratchbird.mojo:1612` (`_raise_error`)
- `src/scratchbird.mojo:1511` (`query` wraps operation and propagates failures)
- `src/scratchbird.mojo:1559` (explicit `ScratchBirdError("parameter count mismatch", "07001")`)
- `src/scratchbird_native.mojo:148` (native-bootstrap unsupported-stream SQLSTATE `0A000` prefix)
- `src/scratchbird_native.mojo:277` (native-bootstrap unsupported-query SQLSTATE `0A000` prefix)
- `src/scratchbird_native.mojo:291` (native-bootstrap unsupported-parameterized-query SQLSTATE `0A000` prefix)
- `src/scratchbird_native.mojo:412` (metadata unsupported SQLSTATE `0A000` prefix)
- `src/scratchbird_native.mojo:454` (connect guard SQLSTATE-prefixed error mapping)
- `src/scratchbird_native.mojo:479` (`extract_sqlstate` helper for deterministic SQLSTATE parsing)
- Lane-local test anchors:
- `tests/sbdriver_conformance.mojo:171`
- `tests/sbdriver_conformance.mojo:188`
- `tests/sbdriver_conformance.mojo:209`
- `tests/errors.py:56` (simple-query error propagation of `sqlstate/detail/hint`)
- `tests/errors.py:74` (extended-query error propagation of `sqlstate/detail/hint`)
- `tests/errors.py:89` (auth guard SQLSTATE propagation)
- `tests/errors.py:104` (truncation-style query failure propagation)
- `tests/native_bootstrap.mojo:25` (connect guard SQLSTATE extraction assertions)
- `tests/native_bootstrap.mojo:42` (metadata guard SQLSTATE extraction assertions)
- `tests/native_bootstrap.mojo:172` (unsupported query SQLSTATE `0A000` extraction assertion)
- `tests/native_bootstrap.mojo:182` (unsupported stream SQLSTATE `0A000` extraction assertion)
- Gaps/next actions:
- Expand truncation-path negative coverage to native binary decode once Mojo transport replaces the bridge shim.

## RES (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:1481` (`ScratchBirdConnection.close`)
- `src/scratchbird.mojo:781` (`ScratchBirdStream.close`)
- `src/scratchbird.mojo:1492` (`_begin_operation` circuit-breaker/keepalive/telemetry hooks)
- `src/scratchbird/leak_detector.mojo:56` (`LeakDetector` and guard-based checkin)
- `src/scratchbird/circuit_breaker.mojo:31` (`CircuitBreaker` state transitions)
- `src/scratchbird/keepalive.mojo:29` (`KeepaliveTracker` current-syntax idle/validation state helpers)
- `src/scratchbird/keepalive.mojo:66` (`KeepaliveManager` deterministic registration/due-validation bookkeeping)
- `src/scratchbird/telemetry.mojo:76` (`TelemetryCollector` metrics/slow-log/prometheus scaffold in current syntax)
- `src/scratchbird/pipeline.mojo:20` (`QueryPipeline` deterministic queue/flush accounting scaffold)
- Lane-local test anchors:
- `tests/integration.mojo:31`
- `tests/sbdriver_conformance.mojo:212`
- `tests/txn_exec_parity.py:320` (idempotent close behavior for connection and stream)
- `tests/lifecycle_scaffolds.mojo:20` (keepalive/telemetry/pipeline deterministic scaffold smoke coverage)
- Gaps/next actions:
- Wire lifecycle scaffold collectors into the active runtime path once native transport cutover work starts using current Mojo syntax.
