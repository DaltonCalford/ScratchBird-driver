# ScratchBird Driver Implementation Audit (SBWP v1.1)

Status: In Progress
Last Updated: 2026-03-12
Scope: All drivers and adapters in this repository (core language drivers, JDBC/ODBC, Superset, Metabase, Mojo/Dart/Swift/Elixir, C++ client, CLI tools).

## Method

Reviewed driver implementations against:
- `docs/specifications/NATIVE_PROTOCOL_ALIGNMENT.md`
- `docs/specifications/TYPE_MAPPING_MATRIX.md`
- `docs/specifications/DRIVER_ERROR_MAPPING.md`
- `docs/specifications/PREPARE_BIND_REQUIREMENTS.md`
- `docs/specifications/DRIVER_STREAMING_AND_PAGING.md`
- `docs/specifications/DRIVER_CANCELLATION_TIMEOUTS.md`
- `docs/specifications/DRIVER_METADATA_JDBC_ODBC_MAPPING.md`
- ScratchBird server source for sys.* view schemas:
  - `ScratchBird/src/catalog/sys_catalog.cpp`

## Cross-Driver Summary

Core drivers (Go, Node, Python, Ruby, Rust, PHP, R, Pascal, .NET, JDBC, ODBC) implement SBWP v1.1 messaging, SCRAM auth, server-side prepare/bind, binary-only enforcement, and zstd rejection. Most also implement notifications, ping, and set_option. Dart/Swift/Elixir/Mojo are partial and do not meet the full SBWP conformance requirements.

Common gaps (where applicable):
- Several lanes still retain class-prefix-only SQLSTATE mapping or incomplete
  per-code coverage, but JDBC is no longer in that bucket.
- Type mapping coverage varies by driver; Dart/Swift/Elixir/Mojo are still
  missing large portions of the type matrix, while the C/C++ lane now exposes
  the required PH5 public type/metadata surface.
- Metadata helper queries are present for most language drivers. Superset and
  Metabase are now aligned to the finalized sys.columns/sys.index_columns
  schema and current JDBC metadata surface; the remaining metadata-helper gaps
  are in Dart/Swift/Elixir/Mojo.

## Driver Audit

### C/C++ (libscratchbird_client) `tracks/p3/drivers/cpp/`
Implemented:
- SBWP v1.1 framing, SCRAM, PARSE/BIND/EXECUTE, portal paging, notifications.
- C API `SET_OPTION`/`PING`, metadata helpers, typed/public result metadata,
  and binary-backed complex-type access.
- C++ wrapper metadata helpers for `schemas`, `tables`, `columns`, `indexes`,
  and DDL-editor schema payload shaping.
- C++ wrapper transaction state tracking aligned to ScratchBird's
  always-in-transaction session model.
Outstanding:
- Listener-mediated/IP transport is the intended boundary; broader
  embedded/named-pipe expansion is outside the currently supported lane.
- Full SQLSTATE-by-code remapping remains part of the broader cross-driver
  portfolio work, not a unique C/C++ blocker.

### ODBC `tracks/p3/drivers/odbc/`
Implemented:
- SBWP v1.1 client via C++ bridge, binary transfer, cancel, prepare/bind, and catalog metadata mappings (sys.* + information_schema for PK/FK).
Outstanding:
- Type mapping is still limited to ODBC-friendly types; complex SBWP types are returned as text/binary without rich wrappers.

### Go `tracks/p3/drivers/go/`
Implemented:
- SBWP v1.1 protocol, SCRAM, server-side prepare/bind, paging, cancel, notifications, set_option, ping.
- Type mapping including composite, range, geometry, vector literal, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Node.js `tracks/p3/drivers/node/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option, ping.
- Type mapping including composite, range, geometry, vector literal, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Python `tracks/p3/drivers/python/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Ruby `tracks/p3/drivers/ruby/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Rust `tracks/p3/drivers/rust/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### PHP `tracks/p3/drivers/php/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, vector literal, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### R `tracks/p3/drivers/r/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, vector literal, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Pascal/Delphi `tracks/p3/drivers/pascal/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, vector literal, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### .NET `tracks/p3/drivers/dotnet/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, vector literal, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### JDBC `tracks/p3/drivers/jdbc/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- JDBC DatabaseMetaData for PK/FK/indexes using information_schema and sys.*.
- Type mapping for arrays, JSONB, ranges, structs.
- Current schema now resolves from explicit client override or the server-side
  user/role/group schema policy, with server fallback preserved instead of
  forcing plain `public`.
- Connection and pooling behavior now reflect ScratchBird's
  always-in-a-transaction model, including post-commit/post-rollback immediate
  usability and schema/autocommit reset on pool reuse.
- SQLSTATE mapping is covered by the JDBC lane's per-code mapping tests.
Outstanding:
- No unique PH5 blocker remains for the baseline JDBC lane; residual work is
  downstream consumer alignment on top of the closed JDBC surface.

### Dart `tracks/p3/drivers/dart/`
Implemented:
- SBWP v1.1 framing, SCRAM, parse/bind, basic query and paging.
- Range decoding and geometry wrapper types.
Outstanding:
- Binary-only enforcement missing.
- Compression rejection missing.
- TLS is optional (sslmode=disable allowed).
- Type mapping incomplete (arrays, composites, vectors, inet/cidr/macaddr, tsvector/tsquery wrappers).
- No metadata helper APIs.
- No conformance/integration tests beyond basic config tests.

### Swift `tracks/p3/drivers/swift/`
Implemented:
- SBWP v1.1 framing, SCRAM, parse/bind, basic query.
- TLS is implemented via NIOSSL (Apple + Linux).
- Basic type encoding/decoding (numeric, JSON/JSONB, UUID, geometry).
Outstanding:
- Binary-only enforcement missing.
- Compression rejection missing.
- Type mapping incomplete (arrays, composites, ranges, inet/cidr/macaddr, vectors).
- No metadata helper APIs.
- No conformance/integration tests.

### Elixir (Ecto) `tracks/p3/drivers/elixir/`
Implemented:
- SBWP v1.1 framing, SCRAM, parse/bind, notifications, set_option, ping.
- Basic type encoding/decoding (json/jsonb, range, geometry).
Outstanding:
- TLS can be disabled.
- Binary-only enforcement missing.
- Compression rejection missing.
- Type mapping incomplete (arrays, composites, vectors, inet/cidr/macaddr).
- Ecto adapter incomplete for full metadata coverage.
- No conformance/integration tests.

### Mojo `tracks/p3/drivers/mojo/`
Implemented:
- Config wrapper and Python-bridge adapter.
Outstanding:
- Not a native SBWP client; relies on Python driver.
- No Mojo-native type wrappers or metadata helpers.
- No conformance/integration tests.

### Superset `tracks/beta/integrations/scratchbird-superset-driver/`
Implemented:
- SQLAlchemy dialect with sys.* metadata queries and information_schema PK/FK.
- DB-API/JDBC-style DSN aliases now normalize to the Python driver contract
  (`currentSchema`/`searchPath`, application/TLS material, manager token).
- Default schema resolution now follows the live session via `SHOW current_schema`
  with `users.public` fallback.
- Index reflection now consumes sys.index_columns/sys.columns instead of
  returning empty column lists.
Outstanding:
- Non-core types still map to the nearest stable SQLAlchemy primitives where
  Superset does not expose richer native types; this is now the supported
  adapter contract rather than a PH5 blocker.

### Metabase `tracks/alpha/integrations/scratchbird-metabase-driver/`
Implemented:
- JDBC-based driver with type mapping table and adapter-side connection
  property shaping on top of the ScratchBird JDBC lane.
- Adapter connection properties now surface current schema override,
  manager-proxy ingress, and the full JDBC `sslmode` set rather than
  hard-restricting the UI to the earlier subset.
- Metadata capability declarations are now explicitly tied to the supported
  JDBC metadata/index surface.
Outstanding:
- Complex SBWP types still map to Metabase base types conservatively; this is
  acceptable adapter behavior and not a remaining PH5 blocker.

### CLI `tracks/p3/drivers/cli/`
Implemented:
- Multiple protocol runners and admin tools.
Outstanding:
- Native SBWP CLI (`sb_isql`) behavior has not been audited against SBWP v1.1 conformance harness.

## Notes

- sys.columns and sys.index_columns schemas are now confirmed from ScratchBird server source (`ScratchBird/src/catalog/sys_catalog.cpp`).
- ODBC metadata queries were aligned to these schemas; remaining driver metadata helpers should now rely on the fixed schema without fallback.
