# ScratchBird Database Drivers

Official database drivers for the [ScratchBird Database Engine](https://github.com/DaltonCalford/ScratchBird).

---

## Project Status

ScratchBird-driver is in **Initial Early Beta (`0.1.0`)**.

All released drivers implement the **ScratchBird Wire Protocol (SBWP v1.1)** baseline handshake and core execution path. However, feature completeness varies significantly by language lane. This README reflects the current audited capability state across drivers.

**Parent Project:** [ScratchBird](https://github.com/DaltonCalford/ScratchBird)  
**Release Targets:** `docs/planning/RELEASE_TARGETS.md`

---

## Capability Model

Each driver is evaluated across the following capability groups:

- **CONN** – Connection lifecycle, TLS enforcement, auth, manager-proxy
- **TXN** – Transaction semantics (autocommit mapping, savepoints)
- **EXEC** – Query execution (prepare/bind/execute, streaming, multi-result)
- **META** – Metadata surfaces (sys.* alignment, schema helpers)
- **TYPE** – Type encode/decode coverage
- **ERR** – Error mapping and SQLSTATE alignment
- **RES** – Resource lifecycle (cursors, statements, pooling, cleanup)

Legend:

- ✅ Implemented (baseline-complete for 0.1.0 scope)
- 🟡 Partial (usable but missing parity elements or integration depth)
- 🔴 Gap (explicitly incomplete or missing surface)

---

# Driver Capability Matrix (Audit Snapshot: 2026-03-06)

Mojo lane note: the prior 8-item JDBC-parity gap batch has been implemented in this audit cycle (hybrid parity path: native facade/bootstrap + opt-in wire bridge + matrixed runtime coverage).

## Alpha Drivers

| Driver | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State |
|--------|------|-----|------|------|------|-----|-----|--------------|
| **Java / JDBC** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Most complete lane |
| **ODBC 3.8** | ✅ | ✅ | ✅ | 🟡 | ✅ | ✅ | ✅ | Near-complete baseline, metadata family parity remains |
| **.NET** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Enterprise lane complete; sustained soak/fault harnesses and cross-runtime contract gate are implemented |
| **Node.js** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | JDBC-parity baseline implemented across TXN/EXEC/META/TYPE with expanded lane tests and env-gated live-depth checks |
| **Python** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with always-on runtime contract gate coverage |
| **Go** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with always-on runtime contract gate coverage |
| **Rust** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with always-on runtime contract gate coverage |
| **Ruby** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | JDBC-parity baseline implemented across CONN/TXN/EXEC/META/TYPE with deterministic wire tests and env-gated live-depth integration checks |
| **PHP** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | ✅ | ERR/RES implemented with expanded lane tests; CONN/TXN/EXEC/META/TYPE remain partial |
| **Pascal** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | ✅ | ✅ | ERR/RES implemented with deterministic lane tests; CONN/TXN/EXEC/META/TYPE remain partial |
| **Mojo** | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ | Hybrid parity complete via native facade/bootstrap + opt-in SBWP wire bridge (`sb_wire_transport=python`), with direct/manager/listener runtime matrices and live-matrix CI gating; pure Mojo socket/TLS cutover remains roadmap work |

---

## Beta Drivers

| Driver | CONN | TXN | EXEC | META | TYPE | ERR | RES | Overall State |
|--------|------|-----|------|------|------|-----|-----|--------------|
| **C/C++ (libscratchbird_client)** | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | Strong C API base, transport gaps |
| **R (DBI)** | 🟡 | 🟡 | ✅ | 🟡 | ✅ | ✅ | 🟡 | Execution/type/error parity is strongest; CONN/TXN/META/RES depth remains in progress |
| **Swift (Async/Await)** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | CONN implemented with expanding deterministic parity tests; broader live integration remains pending |
| **Dart** | ✅ | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | 🟡 | CONN implemented; TYPE/ERR parity significantly expanded (typed exceptions + SQLSTATE parsing/mapping), with direct + manager-proxy integration scaffolding now in place; broader live runtime depth remains pending |

---

## Recent Driver Progress (2026-03-06)

- **.NET lane:** DOTNET-101/102/103 sustained runtime harnesses are now hardened with minimum-duration/threshold controls, summary assertions, and deterministic verifier guards for soak/failover/fault-matrix execution.
- **.NET/JDBC contract lane:** JDBC-203 gate is now profile-aware (`direct`, `manager`, `listener`) with per-profile endpoint + cancel-SQL validation and structured profile-status summaries; latest direct profile run passes for both runtimes.
- **Node lane:** Closed JDBC baseline parity on TXN/EXEC/META/TYPE by adding savepoint/stream env-gated integration checks, richer sys.* metadata row shaping (with JDBC-compatible aliases), and expanded typed OID encode/decode coverage.
- **Dart lane:** Added connection-policy rejection parity tests (`sslmode=disable`, `binary_transfer=false`, `compression=zstd`) and aligned checklist/mapping artifacts.
- **Dart lane:** Expanded type decode and negative-path coverage (core scalar decode paths, text-vs-unknown behavior, range/composite guardrails, unsupported-type checks).
- **Dart lane:** Added env-gated integration suite for direct and manager-proxy connection paths (`SCRATCHBIRD_TEST_DSN`, `SCRATCHBIRD_TEST_MANAGER_DSN`) covering query, transaction lifecycle, metadata wrappers, and JSON/JSONB roundtrips.
- **Dart lane:** Introduced typed driver exception hierarchy and structured server error parsing with SQLSTATE/code propagation + SQLSTATE class-based mapping.
- **Python lane:** Closed JDBC baseline parity across CONN/TXN/EXEC/META/TYPE by accepting non-native protocol hints, enabling `sslmode=disable` + `compression=zstd` + `binary_transfer=false` policy parity, and adding always-on runtime contract gate coverage for transaction/multi-result, metadata wrappers, and runtime type decode semantics.
- **Go lane:** Closed JDBC baseline parity across CONN/TXN/EXEC/META/TYPE by accepting non-native protocol hints, enabling `sslmode=disable` + `compression=zstd` + `binary_transfer=false` policy parity, expanding auth-plugin startup/auth-method handling, broadening OID type coverage (`timetz` + geometry), and adding always-on runtime contract gate coverage for manager-proxy transaction/multi-result, metadata wrappers, and runtime type decode semantics.
- **Rust lane:** Closed JDBC baseline parity across CONN/TXN/EXEC/META/TYPE by enabling negotiated `binary_transfer=false` + `compression=zstd` paths, adding deterministic manager-proxy and password/SCRAM runtime auth coverage, introducing first-class autocommit transition semantics, and adding always-on metadata matrix + DDL payload runtime contract coverage.
- **Ruby lane:** Closed the 15-item parity gap batch by implementing SCRAM+manager/TLS connection coverage, wire-level TXN/EXEC framing parity (`READY` state, portal suspend/resume, true multi-result, close-complete sequencing), expanded metadata collection/restriction families, broader type round-trip matrix assertions, and env-gated live error/resource-depth checks.
- **Mojo lane:** Added opt-in SBWP wire bridge runtime (`sb_wire_transport=python` / `SCRATCHBIRD_MOJO_WIRE_TRANSPORT`) in `src/scratchbird.py` with new `tests/wire_transport_bridge.py` coverage for query/prepare/stream/cancel, transaction/savepoint flow, metadata payloads, lifecycle snapshots, and truncation/decode SQLSTATE propagation (`08006`).
- **Mojo lane:** Expanded integration/conformance harnesses to direct/manager/listener matrix execution (`SCRATCHBIRD_MOJO_*_URLS`) plus long-running stream-cancel and lifecycle snapshot assertions, and added optional live-matrix CI gate (`MOJO_LIVE_MATRIX_ENABLED`) with live DSN vars.
- **Mojo lane:** Expanded restriction-aware metadata query shaping across native/facade/shim execution surfaces, including multi-restriction composition helpers and deterministic rowcount wrappers.
- **Mojo lane:** Added wildcard/escape and null-aware metadata restriction semantics (`LIKE ... ESCAPE '\\'`, `IS NULL`) with deterministic smoke coverage in native bootstrap and facade tests.
- **Mojo lane:** Added broader metadata restriction alias-family support (`catalog`, `index`, `constraint`, `routine`, `type`) with expanded predicate coverage for schema/table/index/constraint/routine/type query families.
- **Mojo lane:** Extended integration smoke metadata checks with deterministic metadata stability and DDL payload contract assertions; synchronized Mojo lane README/checklist/baseline mapping artifacts.
- **Mojo lane:** Expanded integration smoke to cover transaction/savepoint lifecycle and prepare/stream-cancel recovery checks for direct and manager-proxy execution paths.
- **Mojo lane:** Added native-bootstrap DSN host/port parsing fields and deterministic native/facade auth-fail guard parity (`sb_test_auth_fail=true` → `28P01`) with smoke assertions.
- **Mojo lane:** Updated gated CI Mojo lane to run explicit native surface/bootstrap + metadata + integration + conformance sequence.
- **Mojo lane:** Added native timeout alias parsing/guard parity (`connect_timeout|connecttimeout`, `socket_timeout|sockettimeout`, `login_timeout|logintimeout`, `acquire_timeout|acquiretimeout`, fallback `pooling_acquire_timeout|poolingacquiretimeout`) plus `manager-proxy` normalization coverage in native/facade smoke lanes.
- **Mojo lane:** Added expanded front-door alias normalization coverage (`managerproxy`) in native/facade smoke tests.
- **Mojo lane:** Added native credential parsing/override coverage (`user`/`password`, including password-with-colon DSNs and host-only DSN query overrides) in native/facade smoke lanes.
- **Mojo lane:** Updated native deterministic connection identity to include endpoint context (`user@host:port/database`) with smoke assertions in native/facade lanes.
- **Mojo lane:** Added bracketed-IPv6 DSN endpoint parsing coverage and strict native port-range guard parity (`1..65535`) with native/facade smoke assertions.
- **Mojo lane:** Added DSN alias parsing parity for native bootstrap (`username`, `passwd`, `hostname`, `dbname`) with matching native/facade smoke coverage.
- **Mojo lane:** Added JDBC/PG DSN alias parity (`pguser`, `pgpassword`, `pghost`, `pgport`, `pgdatabase`, `servername`, `portNumber`, `databaseName`), added `frontdoormode`/`binarytransfer` alias support, and enforced native-only `protocol|parser|dialect` guards with expanded native/facade smoke coverage.
- **Mojo lane:** Added JDBC-style session property parsing in native bootstrap (`role`, `application_name|applicationname`, `autocommit|auto_commit`, `readonly|read_only`, `current_schema|search_path|searchPath|currentschema`, `default_row_fetch_size|fetch_size|fetchSize|defaultrowfetchsize`) with native/facade guard coverage for non-negative fetch-size defaults.
- **Mojo lane:** Added metadata/session alias parity (`metadata_expand_schema_parents|metadataexpandschemaparents|expand_schema_parents|expandschemaparents|dbeaver_expand_schema_parents|dbeaverexpandschemaparents`) and pooling/manager config parsing (`tcpkeepalive`, `pooling`, `min_pool_size|minpoolsize`, `max_pool_size|maxpoolsize`, `connection_lifetime|connectionlifetime|poolingconnectionlifetime`, `manager_*|mcp_*`), including manager defaults (`manager_connection_profile=native_v3`, `manager_client_intent=native_v3`, `manager_auth_fast_path=true`) with new guard coverage (`08001` manager token required for `manager_proxy`; `22023` guards for `min_pool_size`, `max_pool_size`, `connection_lifetime`, `manager_client_flags`).
- **Mojo lane:** Added protocol canonicalization parity (`protocol|parser|dialect` values `scratchbird`, `scratchbird-native`, `scratchbird_native` now normalize to `native`), `ssl` alias support for `sslmode`, transport compatibility for `binary_transfer|binarytransfer` (`false` accepted), compression normalization/validation parity (`compression=none` → `off`; `compression=zstd` accepted; reject unknown values such as `gzip`), and URL-style query decoding for DSN values (`%xx`, `+`) with malformed percent-escape guard coverage (`22023`).
- **Mojo lane:** Added JDBC config-property parity for `prepareThreshold`, `reWriteBatchedInserts`, `loggerLevel|logLevel`, and `loggerFile|logFile` in native bootstrap parsing (`prepare_threshold|preparethreshold`, `rewrite_batched_inserts|rewritebatchedinserts`, `logger_level|loggerlevel|log_level|loglevel`, `logger_file|loggerfile|log_file|logfile`) with deterministic native/facade default and alias assertions.
- **Mojo lane:** Added JDBC TLS material property parsing parity (`sslrootcert`, `sslcert`, `sslkey`, `sslpassword`; plus underscore aliases) with deterministic native/facade default and alias assertions.
- **Mojo lane:** Added JDBC camelCase alias parity for `currentSchema` and `defaultRowFetchSize`, and aligned native/facade connect behavior to allow `binary_transfer=false` and `compression=zstd` while continuing to reject unsupported compression values (for example `gzip`).
- **Mojo lane:** Added strict malformed-integer DSN guards (`22023`) across numeric property aliases, added malformed bracketed-IPv6 authority guard coverage (`22023`), and aligned invalid `front_door_mode` guard SQLSTATE to `0A000` in native/facade smoke lanes.
- **Mojo lane:** Aligned front-door alias resolution to JDBC query-order (last matching alias wins), defaulted host-omitted DSNs to `localhost`, updated `current_schema` default to `public`, and accepted `sslmode=disable` / `ssl=disable` in native/facade smoke coverage.
- **Mojo lane:** Added closed-connection operation guards (`08003`) across query/begin/stream/metadata paths, with deterministic post-close `ping()` behavior (`false`) in native/facade smoke coverage.
- **Mojo lane:** Added deterministic integer parameter coercion guards (`22023`) for parameterized integer query/prepare paths and DSN pool-bounds validation (`min_pool_size <= max_pool_size`).
- **Mojo lane:** Added prepared statement lifecycle parity with idempotent `close()` and execute-after-close SQLSTATE guard (`HY010`) in native/facade smoke coverage.
- **Mojo lane:** Extended closed-connection SQLSTATE parity (`08003`) to `commit`, `rollback`, `cancel`, and metadata query paths in native/facade smoke coverage.
- **Mojo lane:** Added stream lifecycle SQLSTATE parity: closed-stream reads now report `HY010`, and reads on active streams after connection close report `08003` in native/facade smoke coverage.
- **Mojo lane:** Aligned bridge-shim TXN/EXEC closed-state parity (`08003`) across query/begin/commit/rollback/cancel/stream/metadata, plus bridge-shim statement/stream lifecycle guards (`HY010`) and deterministic integer coercion guard parity (`22023`) in `txn_exec_parity`.
- **Mojo lane:** Aligned bridge-shim CONN guard parity with query-order front-door alias normalization/token enforcement (`08001`), binary transfer and compression compatibility (`binary_transfer=false`, `compression=zstd|none`), deterministic compression rejection for unsupported values, and pool-bound integer guards (`22023`), including updated deterministic manager fallback DSN tokening in integration smoke.
- **Mojo lane:** Added bridge-shim connect guard parity for malformed query escapes and malformed bracketed-IPv6 DSNs (`22023`), protocol alias normalization (`protocol|parser|dialect`) with native-only rejection (`0A000`), and additional integer guard parity for `default_row_fetch_size`, `connection_lifetime`, and `manager_client_flags` (`22023`).
- **Mojo lane:** Extended bridge-shim connect guard parity for endpoint/session constraints with `user/database` required (`28000`), explicit empty-host rejection (`28000`) while preserving omitted-host fallback behavior, port validation (`22023` malformed/range), and timeout guard parity for `connect_timeout`, `socket_timeout`, `login_timeout`, and `acquire_timeout` aliases (`22023`).
- **Mojo lane:** Added bridge-shim malformed-integer guard parity (`22023`) for `prepare_threshold`, `cb_failure_threshold`, `keepalive_max_idle_before_check_ms`, and `pipeline_max_in_flight` via expanded connection guard coverage.
- **Mojo lane:** Extended bridge-shim malformed-integer lifecycle guard parity (`22023`) for `cb_recovery_timeout_ms`, `cb_success_threshold`, `cb_half_open_max_requests`, and `leak_threshold_ms`.
- **Mojo lane:** Added bridge-shim malformed-integer guard parity (`22023`) for `pipeline_auto_flush_threshold`.
- **Mojo lane:** Aligned bridge-shim connect guard SQLSTATE parity for invalid `front_door_mode` and unsupported `compression` (`0A000`), and added alias-precedence/token coverage for `frontdoormode|ingress_mode` with `mcp_auth_token`.
- **Mojo lane:** Added bridge-shim begin-option integer validation parity (`22023`) across transaction knobs (`conflict_action`, `autocommit_mode`, `isolation_level`, `access_mode`, `deferrable`, `wait_mode|wait`, `timeout_ms`) for both wire payload mapping and local shim begin flow, plus closed-connection `prepare` guard parity (`08003`).
- **Mojo lane:** Aligned bridge-shim wire transaction lifecycle state transitions by updating `_txn_id`/savepoint state after begin/commit/rollback, with deterministic parity assertions in `txn_exec_parity`.
- **Mojo lane:** Aligned bridge-shim TLS-required guard SQLSTATE parity for `sslmode=disable` / `ssl=disable` (`0A000`) in connection-guard coverage.
- **Mojo lane:** Added static/wire API closed-connection guards (`08003`) across begin/commit/rollback/savepoint/query helpers to match bridge-shim runtime guard behavior.
- **Mojo lane:** Hardened static/wire savepoint state tracking by normalizing missing/non-list `_savepoints` state and preserving deterministic `3B001` release/rollback-to guards.
- **Mojo lane:** Added static/wire begin-option state parity by persisting normalized begin options on `begin` and clearing them on `commit`/`rollback`, with deterministic TXN parity assertions.
- **Mojo lane:** Expanded static closed-connection metadata helper coverage (`08003`) for `query_metadata_rows`, `query_metadata_restricted`, and `query_metadata_restricted_multi` paths.
- **Mojo lane:** Extended static closed-connection metadata helper coverage (`08003`) to `query_metadata_rows_restricted`, `get_schema`, and `ddl_editor_schema_payload` paths.
- **Mojo lane:** Consolidated static metadata rowcount fallback parity via shared helper semantics (`rowcount` when integer, else `len(rows)` fallback, else `0`) with deterministic TXN parity coverage.
- **Mojo lane:** Extended shared metadata rowcount fallback parity to instance helpers (`query_metadata_rows*`) and added deterministic unsized-row fallback coverage (`0`).
- **Mojo lane:** Added shared metadata row extraction fallback semantics (`rows` list/tuple normalization, unsized rows -> `[]`) for static and instance `get_schema` helper parity.
- **Mojo lane:** Aligned static and instance `ddl_editor_schema_payload` restriction routes with shared metadata rows fallback semantics (tuple normalization and unsized-row `[]` fallback).
- **Mojo lane:** Hardened shared metadata rowcount fallback semantics to treat boolean `rowcount` values as invalid, falling back to `len(rows)`/`0` with deterministic static+instance parity assertions.
- **Mojo lane:** Hardened shared metadata fallback semantics to reject mapping/text and unsupported iterable `rows` payloads across rowcount, `get_schema`, and `ddl_editor_schema_payload` paths (deterministic empty fallback).
- **Mojo lane:** Tightened shared metadata rowcount fallback semantics to accept only non-negative integer rowcount values (negative values now fall back to row-derived counts).
- **Mojo lane:** Aligned bridge-shim metadata helper guard precedence so closed connections return SQLSTATE `08003` before unsupported collection/restriction validation (static and instance paths).
- **Mojo lane:** Expanded metadata restriction alias normalization to accept collapsed/camel forms (for example `tableSchem`, `tableCatalog`, `dataTypeName`) across shim/native surfaces and deterministic metadata tests.
- **Mojo lane:** Added metadata multi-restriction duplicate-alias precedence (`last matching key wins`, including empty-value clear semantics) across shim/native query shaping paths.
- **Mojo lane:** Aligned native timeout alias parsing/guards with shim query-order precedence (`connect/socket/login/acquire` timeout aliases now evaluate by last matching key and reject malformed trailing aliases deterministically).
- **Mojo lane:** Aligned native DSN alias precedence with shim for credential/endpoint/manager families (`user|username|pguser`, `password|passwd|pgpassword`, `host|hostname|servername|pghost`, `database|dbname|databaseName|pgdatabase`, `port|portNumber|pgport`, `manager_auth_token|mcp_auth_token`) and added deterministic trailing-alias malformed-value guard parity for `port` and `default_row_fetch_size` alias families (`22023`).
- **Mojo lane:** Extended native query-order alias precedence parity for `autocommit|auto_commit`, `readonly|read_only`, and TLS material aliases (`ssl_root_cert|sslrootcert`, `ssl_cert|sslcert`, `ssl_key|sslkey`, `ssl_password|sslpassword`), aligned repeated-key `compression` parsing to last-key wins, and added deterministic trailing-alias malformed-value guard coverage for `prepare_threshold`, `connection_lifetime`, and `manager_client_flags` alias families (`22023`).

---

## In Development

| Driver | Notes |
|--------|------|
| **Elixir (Ecto Adapter)** | Functional adapter, SCRAM + type layer present, but no full baseline mapping artifact yet. Considered in-development and not baseline-certified. |

---

## Ecosystem Adapter Status (Alpha Track)

| Adapter | Current State |
|--------|---------------|
| **Prisma adapter** | Deterministic adapter and contract suite implemented; runtime remains blocked by Prisma provider registration (`provider="scratchbird"` unsupported by stock Prisma CLI). |
| **SQLAlchemy dialect** | Deterministic dialect and ORM/reflection contract suite implemented; live runtime matrix is blocked in this shell by endpoint TLS posture mismatch. |
| **Hibernate dialect** | Deterministic dialect and contract suite implemented; runtime JDBC probe now passes with local JDBC jar auto-detected, while full JPA lifecycle/migration matrix remains pending. |
| **TypeORM adapter** | Deterministic adapter and contract suite implemented; runtime remains blocked because stock TypeORM does not recognize `type="scratchbird"` (driver registry gap). |

---

## Overview

This repository contains native database drivers for ScratchBird in multiple programming languages. These drivers target the ScratchBird native protocol (SBWP v1.1) and provide idiomatic APIs for each supported language.

Emulated protocols (PostgreSQL/MySQL/Firebird) are handled by their own native client drivers against ScratchBird's emulation listeners.

---

## Target Features (SBWP v1.1 Baseline)

All baseline drivers aim to implement:

- **Native Wire Protocol (SBWP v1.1)** – ScratchBird native protocol (port 3092)
- **TLS 1.3 Support** – Driver lanes expose configurable TLS posture; production defaults use TLS and lane-specific parity paths may allow explicit disable
- **Server-side Prepare/Bind** – PARSE/BIND/EXECUTE for parameters
- **Transactions** – Always-in-transaction semantics with autocommit mapping
- **Type Mapping** – Full wire type coverage (including composite/geometry/range)
- **Binary transfer and compression policy follow lane parity contracts (for example JDBC-compatible lanes accept `binary_transfer=false` and `compression=zstd`; unknown compression values are rejected)**

---

## Current Enterprise Readiness Tracking

Authoritative gap tracking lives in:

- `docs/planning/DRIVER_ENTERPRISE_READINESS_STRICT_IMPLEMENTATION_MATRIX_*.md`
- `docs/planning/DRIVER_ENTERPRISE_READINESS_REMAINING_GAPS_STRICT_*.md`
- `docs/planning/DRIVER_ENTERPRISE_READINESS_TICKETS_*.md`

This README provides a high-level executive summary. The planning documents remain the ticket-level source of truth.

---

## CLI Tools

| Tool | Purpose | Status |
|------|---------|--------|
| **sb_isql** | Native ScratchBird interactive shell | CONN ✅ / TXN 🟡 / EXEC ✅ / META 🟡 / TYPE 🟡 / ERR ✅ / RES 🟡 |
| **sb_admin** | Server administration CLI | Baseline implemented |
| **sb_backup** | Backup/restore CLI | Baseline implemented |
| **sb_security** | User/role management CLI | Baseline implemented |
| **sb_verify** | Database verification CLI | Baseline implemented |
| **sbdriver-conformance** | SBWP conformance adapter | CONN ✅ / TXN 🟡 / EXEC ✅ / META 🟡 / TYPE 🟡 / ERR ✅ / RES 🟡 (`txn_exec`/`res_loop_exec` parity and typed manifest assertions implemented; live DSN-backed matrix remains partial) |

FDW-based emulation CLI tools remain gated by engine-side adapters.

---

## Project Structure

```
ScratchBird-driver/
├── docs/
├── wiki/
├── tracks/alpha/drivers/cli/
├── tracks/beta/drivers/cpp/
├── tracks/alpha/drivers/odbc/
├── tracks/alpha/drivers/go/
├── tracks/alpha/drivers/python/
├── tracks/alpha/drivers/node/
├── tracks/alpha/drivers/ruby/
├── tracks/alpha/drivers/rust/
├── tracks/alpha/drivers/php/
├── tracks/beta/drivers/r/
├── tracks/alpha/drivers/pascal/
├── tracks/alpha/drivers/dotnet/
├── tracks/alpha/drivers/jdbc/
├── tracks/beta/drivers/dart/
├── tracks/beta/drivers/swift/
├── tracks/p3/drivers/elixir/
├── tracks/alpha/drivers/mojo/
├── CONTRIBUTING.md
├── CHANGELOG.md
└── LICENSE
```

---

## Documentation

- **Documentation Index:** `docs/README.md`
- **Getting Started:** `docs/getting-started/`
- **API Reference:** `docs/api-reference/`
- **Specifications:** `docs/specifications/`
- **Development Guides:** `docs/development/`

---

## Contributing

We welcome contributions. Please review `CONTRIBUTING.md` before submitting pull requests.

---

## License

Licensed under the Initial Developer's Public License (IDPL). See `LICENSE` for details.

---

**Last Updated:** 2026-03-06
