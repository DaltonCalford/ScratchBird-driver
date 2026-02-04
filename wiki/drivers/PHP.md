[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# PHP Driver Guide

**Status:** Alpha track (SBWP v1.1 baseline)
**Last Updated:** 2026-02-04

---

## Overview

Pure-PHP PDO-style driver using the ScratchBird native protocol.

## Install

```bash
composer require scratchbird/scratchbird
```

## Quick Start

```php
use ScratchBird\PDO\ScratchBirdPDO;

$pdo = new ScratchBirdPDO("scratchbird://user:pass@localhost:3092/mydb");
$stmt = $pdo->query("SELECT 1");
$row = $stmt->fetch();
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/php.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/php.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/alpha/drivers/php/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_PHP_URL`.

