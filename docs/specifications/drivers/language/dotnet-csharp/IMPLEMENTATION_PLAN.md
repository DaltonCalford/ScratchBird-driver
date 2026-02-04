# .NET/C# Driver Implementation Plan (Template)

Status: Draft (Template)

## Phase 1 - Core Connectivity

- Connection config + DSN parsing
- TLS enforcement + binary-only
- Basic query execution

## Phase 2 - Type Mapping

- Encode/decode all SBWP types
- Array/composite/range support

## Phase 3 - Metadata

- sys.* helpers per metadata contract
- JDBC/ODBC mapping alignment

## Phase 4 - Conformance

- Conformance tests
- Performance validation
