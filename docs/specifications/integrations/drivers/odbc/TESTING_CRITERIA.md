# ODBC 3.8 Integration Testing Criteria

Status: Draft
Priority: P0
Category: Standard Protocol

## Required Coverage

- Unit tests for encode/decode of all wire types.
- Integration tests against live ScratchBird server.
- Conformance harness integration where applicable.
- Metadata contract validation tests for sys.* queries.

## Integration Validation

- Connectivity tests.
- Metadata discovery.
- Error mapping behavior.
