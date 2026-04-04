# ADBC Best-In-Class Research

Status: Current
Lane: `adbc`
Benchmark: `Apache Arrow ADBC PostgreSQL driver`

## Why This Benchmark

ADBC is the clearest open benchmark for an Arrow-native client surface that
still needs database-grade transactions, metadata, and diagnostics. The Arrow
ADBC PostgreSQL driver sets the reference level for:

- Arrow-native query/export APIs
- bulk ingest and bind flows
- driver-manager interoperability
- database/info and metadata surfaces

## Official Sources

- ADBC documentation root:
  `https://arrow.apache.org/adbc/current/`
- ADBC PostgreSQL driver docs:
  `https://arrow.apache.org/adbc/current/driver/postgresql.html`
- Benchmark implementation anchor:
  `https://github.com/apache/arrow-adbc`

## Capability Families That Become Non-Optional

- `Database`, `Connection`, and `Statement` lifecycle compatibility
- Arrow stream export/import without forced row materialization
- bulk ingest, bind, and partitioned read support
- `GetInfo`, metadata, and transaction behavior
- stable status/error mapping for language bindings above the C driver

## ScratchBird Implementation Implications

- this lane must connect naturally to ScratchBird columnar and analytical
  features rather than wrapping the row driver first
- transaction and metadata correctness must stay aligned to the JDBC/.NET
  baseline where the ADBC surface exposes equivalents
- packaging needs to support both direct use and driver-manager integration

## Later Server Validation Focus

- zero-copy Arrow export proof
- bulk ingest throughput and correctness
- ADBC metadata/info conformance
- cross-language wrapper smoke validation on top of the native driver
