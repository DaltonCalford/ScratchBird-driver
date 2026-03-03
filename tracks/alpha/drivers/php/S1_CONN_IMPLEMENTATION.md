# S1 CONN Implementation (DLB-PHP-002)

Scope: `tracks/alpha/drivers/php` only.

## What Changed

- Improved DSN boolean parsing in `src/Config.php`:
  - Added `parseBool()` helper.
  - `binary_transfer`/`binarytransfer` and `manager_auth_fast_path` now accept `on/off`, `yes/no`, `true/false`, `1/0`.
- Connection preflight in `src/Connection.php` no longer hard-rejects `binary_transfer=false` or `compression=zstd` at connect validation.
- Refactored startup feature calculation into `buildStartupFeatures()` and used it from handshake.
- Added/extended S1-focused lane tests:
  - `tests/ConfigTest.php` for boolean variants and protocol/front-door aliases.
  - `tests/ProtocolConnAuthTest.php` for startup/auth protocol payload parsing.
  - `tests/ConnectionConnTest.php` for connection option compatibility and startup feature-mask behavior.
  - Added `tests/bootstrap.php` and wired new tests to include it.

## Test Commands Run

1. `php vendor/bin/phpunit tests/ConfigTest.php tests/ProtocolConnAuthTest.php tests/ConnectionConnTest.php`
- Result: PASS (`13 tests`, `41 assertions`, `0 failures`).

## CONN Status Recommendation

- Recommendation: `PARTIAL`

## Remaining Gaps

- Connection/auth behavior still lacks broad lane-local integration coverage for all auth/front-door combinations.
- Manager-proxy success/failure matrix is not yet fully validated in deterministic lane tests.
- Compression negotiation is parsed but full compression behavior remains unproven in lane tests.
