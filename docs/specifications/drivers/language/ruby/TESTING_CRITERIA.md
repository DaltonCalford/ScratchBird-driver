# Ruby Driver Testing Criteria

Status: Draft
Priority: P1

## Required Coverage

- Unit tests for encode/decode of all wire types.
- Integration tests against live ScratchBird server.
- Conformance harness integration where applicable.
- Metadata contract validation tests for sys.* queries.

## Performance Tests

- Batch fetch with `fetch_size`.
- Large result set streaming.
- Prepared statement reuse.
