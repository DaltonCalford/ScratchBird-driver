# Java JDBC Driver Testing Criteria

Status: Draft
Priority: P0

## Required Coverage

- Unit tests for encode/decode of all wire types.
- Integration tests against live ScratchBird server.
- Conformance harness integration where applicable.
- Metadata contract validation tests for sys.* queries.
- Deterministic contract tests for connection lifecycle, transactions/savepoints,
  error mapping, and cancel/timeout behavior.
- Release evidence artifacts per `../../../DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`.

## Performance Tests

- Connect/auth latency.
- Batch fetch with `fetch_size`.
- Large result set streaming throughput and peak memory.
- Prepared statement reuse and prepared execute throughput.
- Metadata-call latency for the primary API surface.

## Required Release Evidence

- Publish `CONTRACT_TEST_RESULTS.json` and `CONFORMANCE_REPORT.md`.
- Publish `COMPATIBILITY_MATRIX.md` for supported OS/runtime/toolchain
  combinations.
- Publish `PERFORMANCE_NUMBERS.md` with measured benchmark values.
- Publish `KNOWN_GAPS.md` with severity, workaround, and target milestone.
- Publish `PACKAGING_AND_RELEASE_CADENCE.md` with package channels, semver, and
  support window.
