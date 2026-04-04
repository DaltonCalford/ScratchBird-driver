# Pascal / Delphi Server Verification Packet

Status: server_blocked

## Scope

- lane: `pascal`
- benchmark: `FireDAC`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/pascal`

## Required Environment

- `SCRATCHBIRD_PASCAL_URL`
- `SCRATCHBIRD_PASCAL_STREAM_SQL`
- `SCRATCHBIRD_PASCAL_GENERATED_KEY_SQL`
- `SCRATCHBIRD_PASCAL_GENERATED_KEY_EXPECTED`
- `SCRATCHBIRD_PASCAL_CANCEL_SQL`

## Build / Bootstrap Commands

1. `fpc -Mdelphi -Fu./tracks/p3/drivers/pascal/src -FE./tracks/p3/drivers/pascal/tests ./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests.pas`

## Verification Commands

1. `./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests`

## Expected Artifacts

- `release/readiness/pascal/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/pascal/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/pascal/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/pascal/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/pascal/<version>/KNOWN_GAPS.md`
- `release/readiness/pascal/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/pascal/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/pascal/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
