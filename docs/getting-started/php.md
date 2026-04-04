# PHP Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `PDO_PGSQL`
- Authoritative lane spec: `docs/specifications/drivers/language/php/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/php.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Install

For repo-local development:

```bash
cd tracks/p3/drivers/php
composer install
```

## Quick Start

```php
use ScratchBird\PDO\ScratchBirdPDO;

$pdo = new ScratchBirdPDO("scratchbird://user:pass@localhost:3092/mydb");
$stmt = $pdo->query("SELECT 1");
$row = $stmt->fetch();
```

## Connection Strings

Direct/native:

```
scratchbird://user:password@host:3092/database?sslmode=prefer
```

Manager-proxy:

```
scratchbird://user:password@host:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

Current lane behavior:

- Direct DSNs accept the standard `sslmode` values, including `disable`.
- Compatibility startup keys include `binary_transfer=false` and
  `compression=zstd|none|off`.
- Manager-proxy and auth-plugin startup keys are supported.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_PHP_URL`
