# PHP Server Verification Packet

Status: server_blocked

## Scope

- lane: `php`
- benchmark: `PDO_PGSQL`
- current state: `baseline_complete`
- track root: `tracks/p3/drivers/php`

## Required Environment

- `SCRATCHBIRD_PHP_URL`
- `SCRATCHBIRD_PHP_CANCEL_SQL`

## Build / Bootstrap Commands

1. `cd tracks/p3/drivers/php`
2. `composer install`

## Verification Commands

1. `vendor/bin/phpunit tests`

## Expected Artifacts

- `release/readiness/php/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/php/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/php/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/php/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/php/<version>/KNOWN_GAPS.md`
- `release/readiness/php/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/php/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- all required commands complete successfully
- no required capability failure is hidden behind silent skips
- all release-evidence files are staged under `release/readiness/php/<version>/`
- remaining gaps are explicitly recorded in `KNOWN_GAPS.md`
