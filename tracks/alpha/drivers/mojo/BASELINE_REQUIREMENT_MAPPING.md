# ScratchBird Driver Baseline Requirement Mapping (S0)

## Scope

- Lane-local S0 artifact only for `tracks/alpha/drivers/mojo`.
- Evidence is restricted to files in this lane; no cross-lane claims are made.

## CONN (JDBCBL)

- Current status: Partial (bridge lane implemented + current-syntax native facade/bootstrap)
- Lane-local source anchors:
- `src/scratchbird.mojo:12` (`scratchbird` current-syntax facade exports `ScratchBirdConfig`/`ScratchBirdConnection`/`connect` from native bootstrap)
- `src/scratchbird.mojo:20` (facade exports native `validate_connect_guards`)
- `src/scratchbird_native.mojo:28` (native-bootstrap `ScratchBirdConfig` DSN parsing)
- `src/scratchbird_native.mojo:62` (native-bootstrap lifecycle DSN knob parsing: `cb_*` / `keepalive_*` / `leak_*` / `pipeline_*`)
- `src/scratchbird_native.mojo:634` (native-bootstrap connect guards: TLS/binary/compression/mode/user+db)
- `src/scratchbird_native.mojo:652` (native-bootstrap `connect` entrypoint)
- `src/scratchbird_native.mojo:277` (native-bootstrap `ping` surface)
- `src/scratchbird.py:659` (bridge-shim connect guard enforcement, including deterministic auth-fail simulation)
- `src/scratchbird.py:1037` (bridge-shim `connect` entrypoint)
- Lane-local test anchors:
- `tests/scratchbird_surface.mojo:35` (current-syntax `scratchbird` facade connect/ping/query smoke)
- `tests/scratchbird_surface.mojo:87` (facade guard SQLSTATE assertions)
- `tests/native_bootstrap.mojo:53` (native-bootstrap connect/ping/query smoke)
- `tests/integration.py:71` (integration launcher executes `scratchbird_surface.mojo` + `native_bootstrap.mojo` first)
- `tests/integration.py:156` (deterministic fallback DSN keeps direct integration non-skipping by default)
- `tests/integration.py:164` (deterministic fallback DSN keeps manager-proxy integration non-skipping by default)
- `tests/integration.py:172` (deterministic fallback DSN keeps bad-auth integration non-skipping by default)
- `tests/sbdriver_conformance.py:80` (conformance launcher executes `scratchbird_surface.mojo` + `native_bootstrap.mojo` first)
- `tests/sbdriver_conformance.py:425` (deterministic fallback DSN keeps conformance non-skipping by default)
- Gaps/next actions:
- Implement wire-level native transport/auth path in current-syntax `src/scratchbird.mojo` (facade currently delegates to deterministic native bootstrap scaffolding).
- Add live manager-proxy and bad-auth CI coverage against a running endpoint.

## TXN (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird_native.mojo:156` (native-bootstrap nested `begin()` guard `25001`)
- `src/scratchbird_native.mojo:162` (native-bootstrap inactive `commit` no-op)
- `src/scratchbird_native.mojo:168` (native-bootstrap inactive `rollback` no-op)
- `src/scratchbird_native.mojo:174` (native-bootstrap savepoint create + generated naming)
- `src/scratchbird_native.mojo:184` (native-bootstrap savepoint release guard `3B001`)
- `src/scratchbird_native.mojo:199` (native-bootstrap rollback-to-savepoint trim behavior)
- `src/scratchbird.py:779` (bridge-shim begin option mapping)
- `src/scratchbird.py:786` (bridge-shim inactive `commit` no-op)
- `src/scratchbird.py:792` (bridge-shim inactive `rollback` no-op)
- `src/scratchbird.py:798` (bridge-shim savepoint create guard/name generation)
- `src/scratchbird.py:808` (bridge-shim savepoint release guard `3B001`)
- `src/scratchbird.py:820` (bridge-shim rollback-to-savepoint behavior)
- Lane-local test anchors:
- `tests/native_bootstrap.mojo:67` (native-bootstrap nested `begin()` rejection with `25001`)
- `tests/native_bootstrap.mojo:75` (native-bootstrap savepoint lifecycle + `25000`/`3B001` guards)
- `tests/txn_exec_parity.py:62` (begin option mapping assertions)
- `tests/txn_exec_parity.py:130` (savepoint message/payload parity assertions)
- `tests/txn_exec_parity.py:150` (savepoint guard SQLSTATE assertions)
- `tests/txn_exec_parity.py:230` (shim savepoint lifecycle + rollback-trim assertions)
- Gaps/next actions:
- Add live transaction/savepoint integration coverage against a running ScratchBird endpoint.

## EXEC (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:13` (facade exports native `ScratchBirdConnection` execution surface)
- `src/scratchbird_native.mojo:127` (native-bootstrap `query` rowcount semantics)
- `src/scratchbird_native.mojo:140` (native-bootstrap `query_with_params` + `07001` mismatch)
- `src/scratchbird_native.mojo:152` (native-bootstrap `prepare` statement surface)
- `src/scratchbird_native.mojo:213` (native-bootstrap `stream` surface)
- `src/scratchbird_native.mojo:235` (native-bootstrap `cancel` surface)
- `src/scratchbird_native.mojo:258` (native-bootstrap pipeline queue guard with SQLSTATE `54000`)
- `src/scratchbird_native.mojo:264` (native-bootstrap conditional flush policy honors `pipeline_auto_flush`)
- `src/scratchbird.py:776` (bridge-shim `prepare`)
- `src/scratchbird.py:832` (bridge-shim `stream`)
- `src/scratchbird.py:843` (bridge-shim `cancel`)
- Lane-local test anchors:
- `tests/scratchbird_surface.mojo:46` (facade parameterized/prepare execution assertions)
- `tests/scratchbird_surface.mojo:73` (facade stream/cancel + post-cancel recovery assertions)
- `tests/native_bootstrap.mojo:95` (native-bootstrap prepare-bind + mismatch assertions)
- `tests/native_bootstrap.mojo:154` (native-bootstrap stream/cancel `57014` assertions)
- `tests/native_bootstrap.mojo:175` (native-bootstrap post-cancel recovery assertion)
- `tests/native_bootstrap.mojo:202` (native-bootstrap pipeline-capacity SQLSTATE `54000` assertion)
- `tests/native_bootstrap.mojo:250` (native-bootstrap auto-flush pipeline behavior assertion)
- `tests/native_bootstrap.mojo:263` (native-bootstrap manual-flush retention + close-flush behavior assertion)
- `tests/native_bootstrap.mojo:301` (native-bootstrap breaker-open SQLSTATE `08006` + recovery assertions)
- `tests/scratchbird_surface.mojo:112` (facade pipeline-capacity SQLSTATE `54000` assertion)
- `tests/scratchbird_surface.mojo:160` (facade auto-flush pipeline behavior assertion)
- `tests/scratchbird_surface.mojo:173` (facade manual-flush retention + close-flush behavior assertion)
- `tests/scratchbird_surface.mojo:211` (facade breaker-open SQLSTATE `08006` + recovery assertions)
- `tests/txn_exec_parity.py:196` (shim prepare execute + mismatch assertions)
- `tests/txn_exec_parity.py:263` (shim stream fetch-boundary assertions)
- `tests/txn_exec_parity.py:279` (shim cancel stream SQLSTATE `57014` assertion)
- `tests/sbdriver_conformance.py:204` (manifest `requires` gating for prepare/cancel capabilities)
- Gaps/next actions:
- Add live streamed fetch-boundary and cancellation assertions against long-running server statements.

## META (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:21` (facade metadata constants exported from native bootstrap)
- `src/scratchbird.mojo:40` (facade metadata query helper family)
- `src/scratchbird.mojo:106` (facade `metadata_query_restricted(...)` routed through restriction-aware resolver)
- `src/scratchbird.mojo:119` (facade `metadata_query_restricted_multi(...)` for multi-restriction shaping)
- `src/scratchbird_native.mojo:281` (native-bootstrap `query_metadata`)
- `src/scratchbird_native.mojo:285` (native-bootstrap `query_metadata_rows`)
- `src/scratchbird_native.mojo:289` (native-bootstrap `query_metadata_restricted`)
- `src/scratchbird_native.mojo:302` (native-bootstrap `query_metadata_rows_restricted`)
- `src/scratchbird_native.mojo:315` (native-bootstrap `query_metadata_restricted_multi`)
- `src/scratchbird_native.mojo:328` (native-bootstrap `query_metadata_rows_restricted_multi`)
- `src/scratchbird_native.mojo:628` (native-bootstrap metadata alias normalization)
- `src/scratchbird_native.mojo:641` (native-bootstrap metadata query resolution)
- `src/scratchbird_native.mojo:702` (native-bootstrap metadata restriction alias normalization, including catalog/index/constraint/routine/type aliases)
- `src/scratchbird_native.mojo:728` (native-bootstrap metadata restriction comparator supports exact/wildcard/null (`=`, `LIKE ... ESCAPE '\'`, `IS NULL`) predicates)
- `src/scratchbird_native.mojo:885` (native-bootstrap restriction-aware multi-restriction query resolution + `07001` count guard)
- `src/scratchbird.py:802` (`_ShimConnection.query_metadata_restricted_multi(...)` instance route)
- `src/scratchbird.py:823` (`_ShimConnection.ddl_editor_schema_payload(...)` editor payload helper)
- `src/scratchbird.py:1144` (bridge-shim `query_metadata_restricted_multi` static route)
- `src/scratchbird.py:1181` (`ScratchBirdConnection.ddl_editor_schema_payload(...)` static editor payload helper)
- `src/scratchbird.py:1334` (bridge-shim SQL LIKE matcher helper supports escape-aware, case-insensitive pattern evaluation)
- `src/scratchbird.py:1361` (bridge-shim deterministic schema metadata row shaping supports `=`, `LIKE`, and `IS NULL` filters)
- `src/scratchbird.py:1388` (bridge-shim metadata restriction alias normalization, including catalog/index/constraint/routine/type aliases)
- `src/scratchbird.py:1437` (bridge-shim metadata restriction comparator supports exact/wildcard/null (`=`, `LIKE ... ESCAPE '\'`, `IS NULL`) predicates)
- `src/scratchbird.py:1570` (bridge-shim restriction mapping normalizer + `22023` guard for non-mapping inputs)
- `src/scratchbird.py:1601` (bridge-shim restriction-aware multi-restriction query resolution)
- `src/scratchbird.py:1738` (`build_ddl_editor_schema_payload(...)` deterministic editor payload builder)
- Lane-local test anchors:
- `tests/scratchbird_surface.mojo:56` (facade metadata alias/query/rowcount assertions)
- `tests/scratchbird_surface.mojo:93` (facade restricted metadata query and rowcount assertions)
- `tests/scratchbird_surface.mojo:128` (facade multi-restriction metadata query/rowcount assertions)
- `tests/scratchbird_surface.mojo:194` (facade metadata alias-family restriction assertions for catalog/index/constraint/routine/type)
- `tests/scratchbird_surface.mojo:61` (facade metadata restriction count guard `07001`)
- `tests/native_bootstrap.mojo:113` (native-bootstrap metadata alias/query assertions)
- `tests/native_bootstrap.mojo:166` (native-bootstrap restricted metadata query/rowcount assertions)
- `tests/native_bootstrap.mojo:202` (native-bootstrap multi-restriction metadata query/rowcount assertions)
- `tests/native_bootstrap.mojo:273` (native-bootstrap metadata alias-family restriction assertions for catalog/index/constraint/routine/type)
- `tests/native_bootstrap.mojo:84` (native-bootstrap metadata restriction count guard `07001`)
- `tests/metadata_execution.py:40` (bridge-shim metadata alias normalization coverage)
- `tests/metadata_execution.py:55` (bridge-shim extended metadata query resolution coverage)
- `tests/metadata_execution.py:84` (bridge-shim metadata execution routing coverage)
- `tests/metadata_execution.py:85` (bridge-shim metadata restriction alias normalization coverage)
- `tests/metadata_execution.py:95` (bridge-shim restriction-aware metadata query resolution coverage)
- `tests/metadata_execution.py:84` (bridge-shim metadata restriction alias normalization coverage, including catalog/index/constraint/routine/type aliases)
- `tests/metadata_execution.py:103` (bridge-shim restriction-aware metadata query resolution coverage across alias families)
- `tests/metadata_execution.py:191` (bridge-shim multi-restriction query-shaping + mapping guard coverage)
- `tests/metadata_execution.py:277` (bridge-shim restricted multi-restriction execution routing coverage)
- `tests/metadata_execution.py:328` (bridge-shim restricted multi-restriction rowcount helper coverage)
- `tests/metadata_execution.py:339` (bridge-shim editor payload helper path with schema-pattern restriction shaping)
- `tests/metadata_execution.py:370` (bridge-shim `IS NULL` metadata restriction execution coverage)
- `tests/metadata_execution.py:378` (bridge-shim SQL LIKE escape-aware/case-insensitive matcher coverage)
- `tests/metadata_recursive_schema.py:117` (deterministic editor payload shape contract coverage)
- `tests/metadata_recursive_schema.py:147` (shim connection default editor payload contract coverage)
- `tests/integration.py:129` (integration smoke metadata wrapper rowcount stability assertions)
- `tests/integration.py:135` (integration smoke DDL-editor payload contract-key assertions)
- Gaps/next actions:
- Add live metadata stability assertions (schemas/tables/columns) against running endpoints.
- Add live metadata payload-shaping assertions against running endpoints.

## TYPE (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.py:317` (bridge-shim array/vector/range parser utilities)
- `src/scratchbird.py:537` (bridge-shim type encode wrappers)
- `src/scratchbird.py:599` (bridge-shim type decode wrappers)
- Lane-local test anchors:
- `tests/type_codecs.py:18` (array/range/vector/composite parser and decode assertions)
- `tests/type_codecs.py:53` (geometry/inet/cidr/macaddr decode assertions)
- `tests/type_codecs.py:75` (json/jsonb/uuid decode assertions)
- `tests/type_codecs.py:94` (date/time/timestamp/timestamptz/interval decode assertions)
- `tests/type_codecs.py:125` (array variants including array-of-composite decode assertions)
- `tests/type_codecs.py:138` (OID truncation negative-path assertion)
- Gaps/next actions:
- Implement and validate native Mojo wire-codec parity once full native transport is active.

## ERR (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird.mojo:17` (facade export of native SQLSTATE extractor)
- `src/scratchbird_native.mojo:430` (native-bootstrap unsupported query `0A000`)
- `src/scratchbird_native.mojo:444` (native-bootstrap unsupported parameterized query `0A000`)
- `src/scratchbird_native.mojo:631` (native-bootstrap unsupported metadata `0A000`)
- `src/scratchbird_native.mojo:634` (native-bootstrap guard SQLSTATE error mapping)
- `src/scratchbird_native.mojo:662` (`extract_sqlstate` helper)
- `src/scratchbird.py:236` (bridge-shim `ScratchBirdError` with sqlstate/detail/hint)
- Lane-local test anchors:
- `tests/scratchbird_surface.mojo:18` (facade guard SQLSTATE extraction assertions)
- `tests/native_bootstrap.mojo:18` (native-bootstrap connect guard SQLSTATE extraction assertions)
- `tests/native_bootstrap.mojo:36` (native-bootstrap metadata guard SQLSTATE extraction assertions)
- `tests/native_bootstrap.mojo:326` (unsupported query `0A000` extraction assertion)
- `tests/native_bootstrap.mojo:206` (pipeline-capacity SQLSTATE `54000` extraction assertion)
- `tests/native_bootstrap.mojo:305` (breaker-open SQLSTATE `08006` extraction assertion)
- `tests/scratchbird_surface.mojo:116` (facade pipeline-capacity SQLSTATE `54000` extraction assertion)
- `tests/scratchbird_surface.mojo:215` (facade breaker-open SQLSTATE `08006` extraction assertion)
- `tests/errors.py:74` (bridge-shim simple-path SQLSTATE propagation)
- `tests/errors.py:86` (bridge-shim extended-path SQLSTATE propagation)
- `tests/errors.py:92` (bridge-shim auth guard SQLSTATE propagation)
- Gaps/next actions:
- Add native transport truncation/decode negative-path coverage once wire transport is active.

## RES (JDBCBL)

- Current status: Partial
- Lane-local source anchors:
- `src/scratchbird_native.mojo:238` (native-bootstrap connection close reset semantics)
- `src/scratchbird_native.mojo:251` (native-bootstrap pre-operation circuit-breaker/keepalive validation hook)
- `src/scratchbird_native.mojo:258` (native-bootstrap pipeline-capacity queue guard with SQLSTATE `54000`)
- `src/scratchbird_native.mojo:264` (native-bootstrap post-operation circuit-breaker + keepalive + telemetry update hook)
- `src/scratchbird_native.mojo:117` (native-bootstrap leak-detector checkout initialization)
- `src/scratchbird_native.mojo:123` (native-bootstrap pipeline start initialization)
- `src/scratchbird_native.mojo:244` (native-bootstrap leak-detector release on close)
- `src/scratchbird_native.mojo:312` (native-bootstrap stream close semantics)
- `src/scratchbird.py:766` (bridge-shim connection close)
- `src/scratchbird.py:870` (bridge-shim stream close)
- `src/scratchbird/circuit_breaker.mojo:29` (deterministic circuit-breaker state transitions)
- `src/scratchbird/leak_detector.mojo:31` (deterministic leak detector bookkeeping)
- `src/scratchbird/keepalive.mojo:29` (deterministic keepalive tracker)
- `src/scratchbird/keepalive.mojo:66` (deterministic keepalive manager)
- `src/scratchbird/telemetry.mojo:76` (deterministic telemetry scaffolding)
- `src/scratchbird/pipeline.mojo:20` (deterministic pipeline queue/flush scaffolding)
- Lane-local test anchors:
- `tests/txn_exec_parity.py:320` (idempotent close behavior for connection and stream)
- `tests/lifecycle_scaffolds.mojo:20` (lifecycle scaffolds smoke coverage)
- `tests/scratchbird_surface.mojo:85` (facade smoke asserts telemetry/circuit-breaker/keepalive hooks are active)
- `tests/scratchbird_surface.mojo:90` (facade smoke asserts pipeline/leak-detector hooks are active)
- `tests/native_bootstrap.mojo:179` (native bootstrap smoke asserts telemetry/circuit-breaker/keepalive hooks are active)
- `tests/native_bootstrap.mojo:183` (native bootstrap smoke asserts pipeline/leak-detector hooks are active)
- `tests/native_bootstrap.mojo:255` (native bootstrap smoke asserts auto-flush pipeline drains pending work)
- `tests/native_bootstrap.mojo:269` (native bootstrap smoke asserts manual pipeline retains pending work before close-flush)
- `tests/native_bootstrap.mojo:311` (native bootstrap smoke asserts circuit-breaker half-open recovery semantics)
- `tests/scratchbird_surface.mojo:165` (facade smoke asserts auto-flush pipeline drains pending work)
- `tests/scratchbird_surface.mojo:179` (facade smoke asserts manual pipeline retains pending work before close-flush)
- `tests/scratchbird_surface.mojo:221` (facade smoke asserts circuit-breaker half-open recovery semantics)
- Gaps/next actions:
- Expand lifecycle hook semantics from deterministic scaffolding to real transport timings/backpressure once wire-level transport cutover lands.
