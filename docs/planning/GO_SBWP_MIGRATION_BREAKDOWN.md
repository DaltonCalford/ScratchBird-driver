# Go Driver SBWP v1.1 Migration Breakdown

Status: Draft
Last Updated: 2026-01-09

## Goal

Migrate the Go driver to SBWP v1.1 and server-side prepare/bind while preserving
its public API. This driver will be the reference implementation for other
languages.

## References

- `ScratchBird/docs/specifications/wire_protocols/scratchbird_native_wire_protocol.md`
- `docs/specifications/NATIVE_PROTOCOL_ALIGNMENT.md`
- `docs/specifications/PREPARE_BIND_REQUIREMENTS.md`
- `docs/specifications/TYPE_MAPPING_MATRIX.md`
- `docs/specifications/METADATA_SCHEMA_CONTRACT.md`
- `docs/specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md`

## Phase 0: Harness Adapter (Reference)

1. Implement an in-language harness helper for Go
   - Read manifest + fixtures
   - Execute queries via the Go driver
   - Emit normalized JSON results

2. Use the helper as the reference for the CLI adapter contract

## Phase 1: Protocol Framing and TLS

1. Replace 12-byte SBDB header with 40-byte SBWP header
   - Update `tracks/alpha/drivers/go/protocol.go` encode/decode logic
   - Add attachment_id and txn_id fields to message handling

2. Enforce TLS 1.3 (no plaintext fallback)
   - Confirm TLS is mandatory in connect path
   - Align errors with SBWP expectations

3. Implement STARTUP/AUTH state machine
   - Ensure STARTUP -> AUTH -> AUTH_OK flow
   - Populate attachment_id and txn_id after AUTH_OK

## Phase 2: Message Set Alignment

1. Replace legacy message types with SBWP v1.1 codes
   - QUERY, PARSE, BIND, DESCRIBE, EXECUTE, CLOSE, SYNC, CANCEL

2. Add compression flag support (optional zstd)

3. Maintain sequence numbers for pipelining

## Phase 3: Prepare/Bind/Execute

1. Add PARSE message support
   - Statement name + SQL with $1... placeholders

2. Add DESCRIBE + PARAMETER_DESCRIPTION handling

3. Add BIND message support
   - Text/binary formats
   - NULL length = -1

4. Add EXECUTE + SYNC

5. Remove client-side SQL substitution in `tracks/alpha/drivers/go/query.go`

## Phase 4: Types and Serialization

1. Implement missing types in decode/encode:
   - composite, geometry, macaddr, range

2. Validate array/vector parsing against SBWP type serialization

3. Add round-trip tests for all wire types

## Phase 5: Metadata and Schema

1. Implement search_path application on connect
2. Add metadata queries using sys.* views

## Phase 6: Cancellation and Streaming

1. Add CANCEL message path
2. Expose cancellation in Context APIs
3. Validate large result streaming with backpressure

## Deliverables

- Updated Go driver with SBWP v1.1 framing
- Server-side prepare/bind execution
- Full type coverage
- Conformance test suite passing
