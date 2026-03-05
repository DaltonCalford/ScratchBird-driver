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
- `src/scratchbird.py:152` (bridge-shim connect guard enforcement for TLS/binary/compression/mode/auth-failure simulation)
- `src/scratchbird_native.mojo:23` (native-bootstrap `ScratchBirdConfig`/guard parser path in current Mojo syntax)
- `src/scratchbird_native.mojo:413` (native-bootstrap `connect` entrypoint)
- `src/scratchbird_native.mojo:111` (native-bootstrap `ping` surface)
- `src/scratchbird_native.mojo:69` (native-bootstrap `query_with_params` with placeholder counting and `07001` mismatch semantics)
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
- `tests/sbdriver_conformance.py:70` (conformance launcher now runs native bootstrap smoke first with fallback controls)
- `tests/integration.py:53` (manager-proxy integration smoke branch)
- `tests/integration.py:59` (bad-auth integration smoke branch)
- `tests/native_bootstrap.mojo:50` (native bootstrap connect/ping/query smoke path via `mojo run -I src`)
- `tests/native_bootstrap.mojo:67` (native bootstrap prepare-bind + mismatch guard path)
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
- `src/scratchbird.py:205` (bridge-shim nested-transaction guard rails)
- `src/scratchbird_native.mojo:77` (native-bootstrap `begin` nested-transaction guard `25001`)
- `src/scratchbird_native.mojo:82` (native-bootstrap `commit` no-op when no active txn)
- `src/scratchbird_native.mojo:87` (native-bootstrap `rollback` no-op when no active txn)
- Lane-local test anchors:
- `tests/txn_exec_parity.mojo:55` (`begin` flag/payload mapping assertions)
- `tests/txn_exec_parity.py:89` (nested `begin()` rejection with SQLSTATE `25001`)
- `tests/txn_exec_parity.mojo:90` (inactive transaction commit/rollback no-op assertions)
- `tests/txn_exec_parity.mojo:98` (active transaction commit/rollback message assertions)
- `tests/native_bootstrap.mojo:55` (native-bootstrap nested `begin()` rejection with `25001`)
- `tests/native_bootstrap.mojo:53` (native-bootstrap inactive `commit`/`rollback` no-op assertions)
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
- `src/scratchbird.py:206` (bridge-shim `stream` entrypoint)
- `src/scratchbird.py:217` (bridge-shim `cancel` signal path)
- `src/scratchbird.py:221` (bridge-shim stream iterator with `57014` cancellation behavior)
- `src/scratchbird_native.mojo:69` (native-bootstrap `query_with_params` with placeholder counting + `07001` mismatch)
- `src/scratchbird_native.mojo:73` (native-bootstrap `prepare` statement scaffold)
- `src/scratchbird_native.mojo:146` (native-bootstrap prepared `execute` path)
- `src/scratchbird_native.mojo:92` (native-bootstrap `stream` lifecycle entrypoint)
- `src/scratchbird_native.mojo:104` (native-bootstrap `cancel` signal path)
- `src/scratchbird_native.mojo:130` (native-bootstrap stream iterator with `57014` cancellation behavior)
- `src/scratchbird_native.mojo:213` (native-bootstrap query rowcount semantics for paging queries)
- `src/scratchbird_native.mojo:65` (native-bootstrap operation-level cancel reset before query/stream paths)
- Lane-local test anchors:
- `tests/txn_exec_parity.mojo:108` (`query(..., None)` simple-query path assertion)
- `tests/txn_exec_parity.mojo:117` (`query(..., [])` extended-query path assertion)
- `tests/txn_exec_parity.py:141` (stream fetch-boundary and close lifecycle assertions)
- `tests/txn_exec_parity.py:157` (cancelled stream returns SQLSTATE `57014`)
- `tests/sbdriver_conformance.py:245` (prepare-bind and cancel manifest paths enabled by default)
- `tests/sbdriver_conformance.py:236` (manifest `expect_sqlstate` matching)
- `tests/integration.mojo:22`
- `tests/sbdriver_conformance.mojo:161`
- `tests/sbdriver_conformance.mojo:174`
- `tests/sbdriver_conformance.mojo:190`
- `tests/native_bootstrap.mojo:71` (native-bootstrap prepare-bind + mismatch assertions)
- `tests/native_bootstrap.mojo:73` (native-bootstrap prepared execute parity assertions)
- `tests/native_bootstrap.mojo:54` (native-bootstrap paging query rowcount assertion)
- `tests/native_bootstrap.mojo:135` (native-bootstrap stream/cancel `57014` assertions)
- `tests/native_bootstrap.mojo:141` (native-bootstrap post-cancel stream recovery assertion)
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
- `src/scratchbird_native.mojo:313` (native-bootstrap metadata collection alias normalization)
- `src/scratchbird_native.mojo:360` (native-bootstrap metadata query resolution)
- Lane-local test anchors:
- `tests/metadata_recursive_schema.mojo:24` (database/default branch style row shaping)
- `tests/metadata_recursive_schema.mojo:54` (dotted parent expansion ordering/uniqueness)
- `tests/metadata_recursive_schema.mojo:77` (per-parent uniqueness)
- `tests/metadata_recursive_schema.mojo:94` (same leaf name under different parents)
- `tests/metadata_execution.mojo:16` (metadata execution wrapper entrypoint)
- `tests/metadata_execution.py:38` (collection alias normalization coverage)
- `tests/metadata_execution.py:53` (extended collection query resolution coverage)
- `tests/metadata_execution.py:80` (metadata execution routing path coverage)
- `tests/metadata_execution.py:111` (unsupported metadata collection `0A000` behavior)
- `tests/native_bootstrap.mojo:93` (native-bootstrap metadata alias/query smoke assertions)
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
- `src/scratchbird.py:107` (bridge-shim OID constants and fallback raw-wrapper path)
- `src/scratchbird.py:151` (bridge-shim array/vector/range parser utilities)
- `src/scratchbird.py:217` (bridge-shim encode/decode helpers with truncation guard and unknown-OID fallback)
- Lane-local test anchors:
- `tests/integration.mojo:26`
- `tests/sbdriver_conformance.mojo:182`
- `tests/type_codecs.py:15` (array/range/vector/composite parsing and decode/encode assertions)
- `tests/type_codecs.py:38` (geometry + inet/cidr/macaddr decode assertions)
- `tests/type_codecs.py:67` (unknown-OID fallback + `OID_INT4` truncation behavior)
- Gaps/next actions:
- Expand bridge-shim type coverage toward the remaining native OID matrix (json/jsonb/date/time/timestamp/interval/uuid/array-of-composite) once native Mojo transport is active.

## ERR (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:139` (`ScratchBirdError` with `sqlstate`, `detail`, `hint`)
- `src/scratchbird.py:133` (bridge-shim `ScratchBirdError` now carries `sqlstate/detail/hint`)
- `src/scratchbird.mojo:1127` (`parse_error_message`)
- `src/scratchbird.mojo:1612` (`_raise_error`)
- `src/scratchbird.mojo:1511` (`query` wraps operation and propagates failures)
- `src/scratchbird.mojo:1559` (explicit `ScratchBirdError("parameter count mismatch", "07001")`)
- Lane-local test anchors:
- `tests/sbdriver_conformance.mojo:171`
- `tests/sbdriver_conformance.mojo:188`
- `tests/sbdriver_conformance.mojo:209`
- `tests/errors.py:56` (simple-query error propagation of `sqlstate/detail/hint`)
- `tests/errors.py:74` (extended-query error propagation of `sqlstate/detail/hint`)
- `tests/errors.py:89` (auth guard SQLSTATE propagation)
- `tests/errors.py:104` (truncation-style query failure propagation)
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
- `src/scratchbird/keepalive.mojo:24` (`KeepaliveTracker`)
- `src/scratchbird/telemetry.mojo:145` (`TelemetryCollector`)
- `src/scratchbird/pipeline.mojo:36` (`QueryPipeline` scaffold)
- Lane-local test anchors:
- `tests/integration.mojo:31`
- `tests/sbdriver_conformance.mojo:212`
- `tests/txn_exec_parity.py:176` (idempotent close behavior for connection and stream)
- Gaps/next actions:
- Complete or remove placeholder lifecycle paths (`pass` markers in keepalive/telemetry/pipeline scaffolds) to reduce ambiguity.
