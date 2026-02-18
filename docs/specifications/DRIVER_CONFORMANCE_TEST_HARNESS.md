# Driver Conformance Test Harness (Shared)

Status: Draft
Last Updated: 2026-02-18

## Purpose

Provide a shared, language-agnostic conformance test harness so all drivers
can verify SBWP v1.1 protocol compliance and full wire type coverage.

## Scope

- SBWP v1.1 handshake, auth, and message framing
- Native parser listener contract (single parser/dialect per configured port)
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
  "suite": "sbwp-v1.1-native-parser",
  "requires": ["tls", "auth", "native_parser", "prepare_bind", "types"],
  "tests": [
    {"id": "handshake", "kind": "native_query", "sql": "SELECT 1", "expect_rows": 1},
    {"id": "auth", "kind": "auth"},
    {"id": "prepare_bind", "kind": "native_prepare_bind", "sql": "SELECT $1::int32", "params": [42]},
    {"id": "describe_mismatch", "kind": "native_prepare_bind", "sql": "SELECT $1, $2", "params": [1], "expect_sqlstate": "07001"},
    {"id": "paging_basic", "kind": "native_query", "sql": "SELECT id FROM basic_table", "dsn_append": "fetch_size=1"},
    {"id": "cancel_stream", "kind": "cancel", "sql": "SELECT a.id FROM basic_table a, basic_table b, basic_table c, basic_table d, basic_table e", "cancel_after_rows": 1, "expect_sqlstate": "57014", "requires": ["cancel"]}
  ]
}
```

Supported test fields:
- `kind`: auth | native_query | native_prepare_bind | cancel
- `kind` compatibility aliases: `query` maps to `native_query`, `prepare_bind` maps to `native_prepare_bind`
- `sql`: SQL to execute (`native_query`/`native_prepare_bind`/`cancel`)
- `params`: bound parameters for `native_prepare_bind`
- `expect_rows`: optional row count assertion
- `expect_sqlstate`: expected SQLSTATE on failure
- `timeout_ms`: per-test timeout in milliseconds (`native_query`/`native_prepare_bind`)
- `dsn_append`: query-string or key-value suffix appended to base DSN
- `requires`: optional list of env-gated requirements
- `cancel_after_rows`: rows to read before issuing CANCEL (cancel kind)

### 2. Driver Adapter Contract

Each driver exposes a thin adapter that can:

- Connect using a DSN
- Enforce native parser listener usage (`protocol=native`; reject parser/protocol auto-fallback)
- Execute a simple native parser query
- Execute PARSE/BIND/EXECUTE with parameters through the native parser listener
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
3. Native parser query path (`protocol=native`, no parser auto-detect fallback)
4. Prepare/bind with nulls and binary formats
5. One-way decode coverage for every wire type (server -> driver)

## Execution Model

- Phase A: Go in-language helper + harness runner for rapid validation
- Phase B: Standardized CLI adapters for all drivers
- CI: run harness per driver with DSN environment variables

## Output and Reporting

- JSON summary with pass/fail per test
- Per-driver report artifacts
- Failures include expected vs actual payloads
