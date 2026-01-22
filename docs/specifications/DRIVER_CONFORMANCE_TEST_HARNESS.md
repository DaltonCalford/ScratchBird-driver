# Driver Conformance Test Harness (Shared)

Status: Draft
Last Updated: 2026-01-09

## Purpose

Provide a shared, language-agnostic conformance test harness so all drivers
can verify SBWP v1.1 protocol compliance and full wire type coverage.

## Scope

- SBWP v1.1 handshake, auth, and message framing
- PARSE/BIND/EXECUTE behavior
- Type encoding/decoding for all wire types
- Cancellation behavior
- Metadata queries (sys.*)

## Harness Shape

### 1. Test Manifest

A JSON manifest defines the test suite and required capabilities:

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

### 2. Driver Adapter Contract

Each driver exposes a thin adapter that can:

- Connect using a DSN
- Execute a simple QUERY
- Execute PARSE/BIND/EXECUTE with parameters
- Stream results and return row data
- Issue CANCEL
- Run metadata queries

CLI adapters must use the executable name `sbdriver-conformance` to keep
invocation consistent across languages.

### 2.1 Adapter Strategy (Hybrid)

Chosen approach:

1. Implement an in-language test helper for the reference driver (Go) to
   validate the contract quickly.
2. Extract a CLI adapter contract from the reference helper (stdin manifest,
   stdout JSON).
3. Implement the CLI adapter for each remaining driver to standardize behavior.

### 3. Result Format

Adapters must emit a normalized JSON result:

```json
{
  "test_id": "prepare_bind",
  "rows": [[42]],
  "columns": ["int32"],
  "status": "ok",
  "errors": []
}
```

### 4. Fixture SQL

A shared SQL fixture file defines schema and seed data used by all tests.
Fixtures live under `docs/fixtures/` (e.g., `core_fixture.sql`,
`types_fixture.sql`).

## Required Tests

1. Handshake (TLS required)
2. Authentication (valid credentials)
3. Prepare/bind with nulls and binary formats
4. One-way decode coverage for every wire type (server -> driver)

## Execution Model

- Phase A: Go in-language helper + harness runner for rapid validation
- Phase B: Standardized CLI adapters for all drivers
- CI: run harness per driver with DSN environment variables

## Output and Reporting

- JSON summary with pass/fail per test
- Per-driver report artifacts
- Failures include expected vs actual payloads
