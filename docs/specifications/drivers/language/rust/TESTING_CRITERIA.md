# Rust Driver Testing Criteria

Status: Current
Priority: P0

## Deterministic Offline Coverage

- static spec/doc authority checks
- fixture and manifest alignment checks
- build/bootstrap command validity against repo-local package metadata
- release-evidence template and path validation

## Later Server-Backed Verification

Required environment inputs:

- `SCRATCHBIRD_RUST_URL`
- `SCRATCHBIRD_RUST_CANCEL_SQL`

Required execution commands:

- `cargo test`

## Required Release Evidence

- `CONTRACT_TEST_RESULTS.json`
- `CONFORMANCE_REPORT.md`
- `COMPATIBILITY_MATRIX.md`
- `PERFORMANCE_NUMBERS.md`
- `KNOWN_GAPS.md`
- `PACKAGING_AND_RELEASE_CADENCE.md`
- `SUMMARY.json`

Use the shared templates in:

`docs/development/release-evidence/`
