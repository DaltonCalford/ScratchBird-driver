# ScratchBird Mojo Driver

Native ScratchBird driver lane for Mojo (SBWP v1.1).

Current implementation is a Mojo-Python interop lane:
- API/runtime shim in `src/scratchbird.py`
- Mojo entrypoints in `tests/*.mojo` invoke paired Python scripts for execution
  under the active Mojo toolchain

## Lane Docs

- [Baseline Requirement Mapping (S0)](BASELINE_REQUIREMENT_MAPPING.md)
- [S2 TXN/EXEC Implementation](S2_TXN_EXEC_IMPLEMENTATION.md)
- [S3 Metadata Implementation](S3_METADATA_IMPLEMENTATION.md)
- [Tests](tests/README.md)

## Status

- Full SBWP v1.1 API surface is represented in-lane through the Python-backed shim.
- Mojo wrappers and test adapter now execute under pixi-managed Mojo toolchains.
- `src/scratchbird.mojo` now compiles in current Mojo syntax as a facade over `src/scratchbird_native.mojo`, with deterministic facade smoke in `tests/scratchbird_surface.mojo`.
- Native bootstrap module in current Mojo syntax is available at `src/scratchbird_native.mojo` and validated by `tests/native_bootstrap.mojo`.
- Native bootstrap currently covers deterministic connect/ping guards, extended metadata alias/query resolution, transaction lifecycle guards (`25001` nested begin), savepoint lifecycle guards (`25000`/`3B001`), prepare-bind mismatch handling, prepared execute parity (including statement-close `HY010` guard behavior), paging-query rowcount semantics, and stream/cancel (`57014`) with post-cancel recovery semantics.
- Native bootstrap DSN parsing now includes transport-ready credentials/endpoint fields (`user`/`password`, `host`, `port`), query override and alias support (`user|username|pguser`, `password|passwd|pgpassword`, `host|hostname|servername|pghost`, `port|portNumber|pgport`, `database|dbname|databaseName|pgdatabase`), JDBC-style session knobs (`role`, `application_name|applicationname`, `autocommit|auto_commit`, `readonly|read_only`, `current_schema|search_path|searchPath|currentschema`, `default_row_fetch_size|fetch_size|fetchSize|defaultrowfetchsize`, `metadata_expand_schema_parents|metadataexpandschemaparents|expand_schema_parents|expandschemaparents|dbeaver_expand_schema_parents|dbeaverexpandschemaparents`), JDBC statement/logging knobs (`prepare_threshold|preparethreshold`, `rewrite_batched_inserts|rewritebatchedinserts`, `logger_level|loggerlevel|log_level|loglevel`, `logger_file|loggerfile|log_file|logfile`), TLS material knobs (`sslrootcert`, `sslcert`, `sslkey`, `sslpassword`, and underscore aliases), pooling knobs (`tcpkeepalive`, `pooling`, `min_pool_size|minpoolsize`, `max_pool_size|maxpoolsize`, `connection_lifetime|connectionlifetime|poolingconnectionlifetime`), manager knobs (`manager_*|mcp_*`, including defaults `manager_connection_profile=native_v3`, `manager_client_intent=native_v3`, `manager_auth_fast_path=true`), bracketed IPv6 host parsing (`[::1]:3092`) plus malformed bracketed-IPv6 guard handling, timeout aliases (`connect_timeout|connecttimeout`, `socket_timeout|sockettimeout`, `login_timeout|logintimeout`, `acquire_timeout|acquiretimeout` with fallback `pooling_acquire_timeout|poolingacquiretimeout`), protocol aliases (`protocol|parser|dialect` with canonicalization of `scratchbird`, `scratchbird-native`, `scratchbird_native` to `native`), front-door mode normalization (`manager-proxy`/`managerproxy`/`managed` → `manager_proxy`) with query-order precedence across `front_door_mode|frontdoormode|connection_mode|ingress_mode` (last matching key wins) and invalid-value `0A000` parity guards, transport alias support (`binary_transfer|binarytransfer`, including `binary_transfer=false` compatibility), `ssl` alias support for `sslmode` (including accepted `disable`), compression normalization/validation (`none` → `off`; `zstd` accepted; unsupported values such as `gzip` rejected), URL-style query decoding for DSN values (`%xx`, `+`), endpoint/timeout/session/pooling/manager guards (host defaults to `localhost` when omitted, explicit empty host rejected, `port` in `1..65535`, timeout values `>= 0`, `default_row_fetch_size >= 0`, `min_pool_size >= 0`, `max_pool_size >= 1`, `min_pool_size <= max_pool_size`, `connection_lifetime >= 0`, `manager_client_flags >= 0`, malformed integer DSN values rejected with deterministic `22023` errors, manager token required for manager-proxy via `08001`, malformed percent escapes rejected with `22023`), and deterministic auth-fail guard parity via `sb_test_auth_fail=true` (`28P01`) in native/facade smoke coverage.
- Native bootstrap now enforces closed-connection operation guards (`08003`) across query/begin/commit/rollback/cancel/stream/metadata paths, deterministic `ping()` behavior after close (`false`), and deterministic integer-parameter coercion guards (`22023`) for parameterized integer query/prepare execution.
- Stream lifecycle parity now includes deterministic closed-stream read guard behavior (`HY010`) and active-stream read guards against closed connections (`08003`).
- Native bootstrap connection identity now includes endpoint context (`user@host:port/database`) and is asserted in both native/facade smoke lanes for deterministic lifecycle tracking hooks.
- Native bootstrap guard and unsupported-operation failures now use deterministic SQLSTATE-prefixed error strings with extractor coverage (`extract_sqlstate`) in lane tests.
- Metadata execution parity now includes deterministic metadata restriction helpers (`normalize_metadata_restriction_key`, `resolve_metadata_collection_query_restricted`, `resolve_metadata_collection_query_restricted_multi`, `query_metadata_restricted`, `query_metadata_rows_restricted`, `query_metadata_restricted_multi`, `query_metadata_rows_restricted_multi`) with expanded alias keys (`catalog`/`index`/`constraint`/`routine`/`type`) and cross-collection schema/table/index/constraint/routine/type restriction predicates, exact/wildcard/null restriction shaping (`=`, `LIKE ... ESCAPE '\\'`, `IS NULL`) including escaped wildcard patterns, SQLSTATE guards for invalid restriction payloads (`07001` native count mismatch / `22023` shim non-mapping restrictions), deterministic DDL-editor payload shaping helpers (`build_ddl_editor_schema_payload`, `ddl_editor_schema_payload`), and executable rowcount coverage in shim/native bootstrap/facade scaffolds.
- Integration smoke now exercises transaction/savepoint lifecycle and prepare/stream-cancel recovery checks in-lane, plus metadata stability/payload checks with schemas/tables/columns rowcount relationship invariants, alias-family restriction execution checks, `ddl_editor_schema_payload(...)` contract/tree-parent checks, and deterministic fallback content assertions for schema restriction/payload shaping.
- Native bootstrap query/stream paths now exercise circuit-breaker/keepalive/telemetry hooks plus leak-detector/pipeline lifecycle scaffolds (deterministic integration), including deterministic SQLSTATE guards for pipeline-capacity (`54000`) and circuit-breaker-open (`08006`) behavior, auto-vs-manual pipeline flush semantics, and half-open breaker recovery checks.
- Integration and conformance launchers are native-smoke-first (`tests/scratchbird_surface.mojo` then `tests/native_bootstrap.mojo`) with bridge-shim fallback controls.
- Bridge-shim connection parity now includes `prepare`/statement execute lifecycle guards (`HY010` closed statement, `08003` prepare-on-closed-connection), deterministic integer-parameter coercion guards (`22023`), deterministic `ping`, transaction/savepoint helpers, begin-option integer validation parity for `conflict_action|autocommit_mode|isolation_level|access_mode|deferrable|wait_mode|wait|timeout_ms` (`22023`), wire transaction state transitions (`_txn_id` + savepoint reset on begin/commit/rollback), static/wire begin-option state persistence/clear semantics (`_txn_begin_options` on begin, clear on commit/rollback), static/wire closed-connection guards (`08003`) across begin/commit/rollback/savepoint/query helpers (including metadata rowcount/restriction helpers, `get_schema`, and `ddl_editor_schema_payload` routes), shared metadata rowcount fallback semantics for both static and instance helpers (`rowcount` integer else `len(rows)` else `0`, including unsized-row fallback), deterministic static savepoint tracking initialization for missing/non-list `_savepoints`, and closed-connection operation guards (`08003`) across query/begin/commit/rollback/cancel/stream/metadata used by lane tests; connect-guard parity now also includes query-order front-door alias normalization/token enforcement (`front_door_mode|frontdoormode|connection_mode|ingress_mode`, last matching key wins, `08001` token guard), compatibility for `binary_transfer=false` / `binarytransfer=false` and `compression=zstd|none`, TLS-required `sslmode|ssl=disable` rejection plus invalid front-door/unsupported compression SQLSTATE parity (`0A000`), acceptance of manager token alias `mcp_auth_token`, malformed query-escape and malformed bracketed-IPv6 DSN guards (`22023`), native-only protocol alias normalization/rejection for `protocol|parser|dialect` (`0A000`), explicit `user/database` required and empty-host endpoint guards (`28000`), port validity/range guards (`22023`), timeout alias guards (`connect_timeout|connecttimeout`, `socket_timeout|sockettimeout`, `login_timeout|logintimeout`, `acquire_timeout|acquiretimeout`, fallback `pooling_acquire_timeout|poolingacquiretimeout` with `>=0` enforcement), and extended pooling/session/lifecycle integer guards (`prepare_threshold`, `default_row_fetch_size`, `min_pool_size`, `max_pool_size`, `connection_lifetime`, `manager_client_flags`, `cb_failure_threshold`, `cb_recovery_timeout_ms`, `cb_success_threshold`, `cb_half_open_max_requests`, `keepalive_max_idle_before_check_ms`, `leak_threshold_ms`, `pipeline_max_in_flight`, `pipeline_auto_flush_threshold`) with deterministic `22023` validation.
- Bridge-shim type codecs now include temporal/json/jsonb/uuid wrappers and array-of-composite encode/decode coverage for deterministic lane testing.
- Lifecycle scaffolds (`circuit_breaker`/`leak_detector`/`keepalive`/`telemetry`/`pipeline`) now compile in current Mojo syntax and have dedicated deterministic smoke coverage in `tests/lifecycle_scaffolds.mojo`.
- Native Mojo transport/auth remains future work.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Experimental | Validated with pixi-managed Mojo toolchain. |
| Windows | Not supported | No CI/toolchain path configured. |
| macOS | Not supported | No CI/toolchain path configured. |

## Requirements

- Python 3.10+
- Mojo toolchain (recommended: `pixi` workspace at `~/mojo-work/sb-mojo`)

## Verification

From `tracks/alpha/drivers/mojo`:

```bash
pixi run -m ~/mojo-work/sb-mojo --executable mojo run -I src -I src/scratchbird tests/native_bootstrap.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run -I src -I src/scratchbird tests/scratchbird_surface.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/metadata_recursive_schema.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/txn_exec_parity.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/errors.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/type_codecs.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/connection_guards.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run -I src/scratchbird tests/lifecycle_scaffolds.mojo
pixi run -m ~/mojo-work/sb-mojo --executable mojo run tests/integration.mojo
tests/sbdriver-conformance --manifest ../../../../docs/fixtures/sbwp_conformance_manifest.json
```

CI (`.github/workflows/ci.yml`, Mojo gated lane) now runs an explicit sequence:
`scratchbird_surface.mojo`, `native_bootstrap.mojo`, `metadata_execution.mojo`,
`metadata_recursive_schema.mojo`, `integration.py`, and `sbdriver-conformance`.

Optional launcher env vars:
- `SCRATCHBIRD_MOJO_URL` for direct smoke
- `SCRATCHBIRD_MOJO_MANAGER_URL` for manager-proxy smoke
- `SCRATCHBIRD_MOJO_BAD_AUTH_URL` for bad-auth smoke (shim-mode deterministic path can append `sb_test_auth_fail=true`)
- `SCRATCHBIRD_MOJO_SKIP_NATIVE_BOOTSTRAP` to bypass native smoke (`tests/scratchbird_surface.mojo` and `tests/native_bootstrap.mojo`) in `tests/integration.mojo` and `tests/sbdriver_conformance.py`
- `SCRATCHBIRD_MOJO_NATIVE_REQUIRED` to fail when native bootstrap launcher is unavailable/failing
- `SCRATCHBIRD_MOJO_DISABLE_FALLBACK_DSN` to require explicit `SCRATCHBIRD_MOJO_URL` / `SCRATCHBIRD_MOJO_MANAGER_URL` / `SCRATCHBIRD_MOJO_BAD_AUTH_URL` for integration/conformance (default lane behavior uses deterministic fallback DSNs)

Deterministic native lifecycle DSN knobs (for lane smoke/testing):
- `cb_failure_threshold`
- `cb_recovery_timeout_ms`
- `cb_success_threshold`
- `cb_half_open_max_requests`
- `keepalive_max_idle_before_check_ms`
- `leak_threshold_ms`
- `pipeline_max_in_flight`
- `pipeline_auto_flush`
- `pipeline_auto_flush_threshold`

## Next Steps

- Replace the Python transport bridge with native Mojo sockets/TLS
- Add Mojo-native streaming helpers and type wrappers
