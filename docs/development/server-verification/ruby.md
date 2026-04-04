# Ruby Server Verification Packet

Status: server_blocked

## Scope

- lane: `ruby`
- benchmark: `ruby-pg`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/ruby`

## Required Environment

- `SCRATCHBIRD_RUBY_URL`
- `SCRATCHBIRD_RUBY_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/ruby`
2. `gem build scratchbird.gemspec`

## Verification Commands

1. `ruby -Ilib:test test/*.rb`

## Expected Artifacts

- `release/readiness/ruby/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/ruby/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/ruby/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/ruby/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/ruby/<version>/KNOWN_GAPS.md`
- `release/readiness/ruby/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/ruby/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/ruby/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
