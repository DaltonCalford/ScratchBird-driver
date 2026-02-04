# ScratchBird Driver Implementation Audit (SBWP v1.1)

Status: In Progress
Last Updated: 2026-02-04
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
- Error mapping is class-prefix based in most drivers (SQLSTATE class only), not full SQLSTATE-by-code mapping.
- Type mapping coverage varies by driver; C++/Dart/Swift/Elixir/Mojo are missing large portions of the type matrix.
- Metadata helper queries are present for most language drivers, but Superset/Metabase require further alignment with sys.columns/sys.index_columns now that the server schema is finalized.

## Driver Audit

### C/C++ (libscratchbird_client) `cpp/`
Implemented:
- SBWP v1.1 framing, SCRAM, PARSE/BIND/EXECUTE, portal paging, notifications.
Outstanding:
- Type mapping coverage is limited to a small subset of SBWP types in the public C API.
- No sys.* metadata helpers or higher-level metadata API.
- No direct SET_OPTION/PING helpers exposed at C API level.

### ODBC `odbc/`
Implemented:
- SBWP v1.1 client via C++ bridge, binary transfer, cancel, prepare/bind, and catalog metadata mappings (sys.* + information_schema for PK/FK).
Outstanding:
- Type mapping is still limited to ODBC-friendly types; complex SBWP types are returned as text/binary without rich wrappers.

### Go `go/`
Implemented:
- SBWP v1.1 protocol, SCRAM, server-side prepare/bind, paging, cancel, notifications, set_option, ping.
- Type mapping including composite, range, geometry, vector literal, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Node.js `node/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option, ping.
- Type mapping including composite, range, geometry, vector literal, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Python `python/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Ruby `ruby/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Rust `rust/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### PHP `php/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, vector literal, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### R `r/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, vector literal, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Pascal/Delphi `pascal/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, vector literal, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### .NET `dotnet/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- Type mapping including composite, range, geometry, arrays, vector literal, inet/cidr/macaddr.
- Metadata helpers for sys.schemas/sys.tables/sys.columns.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### JDBC `jdbc/`
Implemented:
- SBWP v1.1 protocol, SCRAM, prepare/bind, paging, cancel, notifications, set_option.
- JDBC DatabaseMetaData for PK/FK/indexes using information_schema and sys.*.
- Type mapping for arrays, JSONB, ranges, structs.
Outstanding:
- Error mapping is SQLSTATE class-prefix based.

### Dart `dart/`
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

### Swift `swift/`
Implemented:
- SBWP v1.1 framing, SCRAM, parse/bind, basic query.
- Basic type encoding/decoding (numeric, JSON/JSONB, UUID, geometry).
Outstanding:
- No TLS implementation (TCP only).
- Binary-only enforcement missing.
- Compression rejection missing.
- Type mapping incomplete (arrays, composites, ranges, inet/cidr/macaddr, vectors).
- No metadata helper APIs.
- No conformance/integration tests.

### Elixir (Ecto) `elixir/`
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

### Mojo `mojo/`
Implemented:
- Config wrapper and Python-bridge adapter.
Outstanding:
- Not a native SBWP client; relies on Python driver.
- No Mojo-native type wrappers or metadata helpers.
- No conformance/integration tests.

### Superset `scratchbird-superset-driver/`
Implemented:
- SQLAlchemy dialect with sys.* metadata queries and information_schema PK/FK.
- Enforces binary transfer and TLS requirement.
Outstanding:
- `get_columns` still falls back to using numeric `data_type_id`; should use `data_type_name` from sys.columns without fallback now that server schema is fixed.
- Type mapping for non-core types is minimal (arrays, ranges, geometry are mapped to generic types).

### Metabase `scratchbird-metabase-driver/`
Implemented:
- JDBC-based driver with type mapping table and TLS/binary transfer enforcement.
Outstanding:
- Feature flags need to be revalidated against current JDBC metadata coverage.
- Type mapping for complex SBWP types is generic.

### CLI `cli/`
Implemented:
- Multiple protocol runners and admin tools.
Outstanding:
- Native SBWP CLI (`sb_isql`) behavior has not been audited against SBWP v1.1 conformance harness.

## Notes

- sys.columns and sys.index_columns schemas are now confirmed from ScratchBird server source (`ScratchBird/src/catalog/sys_catalog.cpp`).
- ODBC metadata queries were aligned to these schemas; remaining driver metadata helpers should now rely on the fixed schema without fallback.
