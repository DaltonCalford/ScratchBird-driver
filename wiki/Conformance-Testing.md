# Conformance Testing

The shared conformance harness validates SBWP v1.1 protocol compliance and wire type coverage across released drivers. In-development drivers are not fully covered yet.

## Overview

The harness uses:
- A JSON manifest defining test cases
- SQL fixture files for schema and seed data
- Per-driver adapters that execute tests and report results

## Test Manifest

The manifest defines required capabilities and test cases:

```json
{
  "schema_version": "1.0",
  "protocol_version": "sbwp-1.1",
  "suite": "sbwp-v1.1",
  "requires": ["tls", "auth", "prepare_bind", "types"],
  "tests": [
    {"id": "handshake", "sql": "SELECT 1"},
    {"id": "auth", "action": "authenticate"},
    {"id": "prepare_bind", "sql": "SELECT $1::int32", "params": [42]},
    {"id": "types", "sql": "SELECT $1::uuid, $2::jsonb", "params": ["...", "{...}"]}
  ]
}
```

## Required Tests (Core Drivers)

1. **Handshake** - TLS 1.3 required
2. **Authentication** - Valid credentials via SCRAM-SHA-256
3. **Prepare/Bind** - With nulls and binary formats
4. **Type Coverage** - One-way decode for every wire type
5. **Streaming/Paging** - Portal paging with MSG_PORTAL_SUSPENDED
6. **Cancellation** - Query timeout and CANCEL message handling

## Fixtures

SQL fixtures define schema and seed data:

- `core_fixture.sql` - Basic tables and data
- `types_fixture.sql` - Type coverage test data

Fixtures are loaded before running conformance tests.

## Driver Adapter Contract

Each driver exposes a thin adapter that can:

- Connect using a DSN
- Execute simple QUERY
- Execute PARSE/BIND/EXECUTE with parameters
- Stream results and return row data
- Issue CANCEL
- Run metadata queries

CLI adapters use the executable name `sbdriver-conformance` for consistent invocation.

## Result Format

Adapters emit normalized JSON results:

```json
{
  "test_id": "prepare_bind",
  "rows": [[42]],
  "columns": ["int32"],
  "status": "ok",
  "errors": []
}
```

## Running Tests

### Go

```bash
cd go
SCRATCHBIRD_GO_URL="scratchbird://user:pass@localhost:3092/db" \
SCRATCHBIRD_CONFORMANCE_MANIFEST="../docs/fixtures/sbwp_conformance_manifest.json" \
go test ./conformance
```

### Python

```bash
cd python
SCRATCHBIRD_TEST_DSN="scratchbird://user:pass@localhost:3092/db" \
pytest tests/conformance/
```

### Node.js

```bash
cd node
SCRATCHBIRD_NODE_URL="scratchbird://user:pass@localhost:3092/db" \
npm run test:conformance
```

### Other Drivers

Each driver follows the same pattern:
1. Set the DSN environment variable
2. Set the manifest path (if required)
3. Run the conformance test suite

## Environment Variables

| Driver | DSN Variable |
|--------|--------------|
| Go | SCRATCHBIRD_GO_URL |
| Python | SCRATCHBIRD_TEST_DSN |
| Node.js | SCRATCHBIRD_NODE_URL |
| Ruby | SCRATCHBIRD_RUBY_URL |
| Rust | SCRATCHBIRD_RUST_URL |
| PHP | SCRATCHBIRD_PHP_URL |
| R | SCRATCHBIRD_R_URL |
| Pascal | SCRATCHBIRD_PASCAL_URL |
| .NET | SCRATCHBIRD_DOTNET_URL |
| JDBC | SCRATCHBIRD_JDBC_URL |

## CI Integration

- Run harness per driver with DSN environment variables
- Generate JSON summary with pass/fail per test
- Produce per-driver report artifacts
- Failures include expected vs actual payloads
- Cross-platform testing on Windows and Linux

## Build Matrix

See `docs/BUILD_MATRIX.md` for complete build and test commands across all platforms.

**Last Updated:** 2026-02-18
