# kafka Integration Testing Criteria

Status: Draft
Priority: P1
Category: Big Data & Streaming

## Required Coverage

- Unit tests for encode/decode of all wire types.
- Integration tests against live ScratchBird server.
- Conformance harness integration where applicable.
- Metadata contract validation tests for sys.* queries.

## Integration Validation

- Connectivity tests.
- Metadata discovery.
- Error mapping behavior.
