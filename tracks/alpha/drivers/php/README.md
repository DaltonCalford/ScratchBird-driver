# ScratchBird PDO Driver (Userland)

Pure-PHP ScratchBird PDO-style driver using the native wire protocol.

## Documentation

- [Getting started](../../../../docs/getting-started/php.md)
- [API reference](../../../../docs/api-reference/php.md)
- Baseline requirement mapping: [BASELINE_REQUIREMENT_MAPPING.md](BASELINE_REQUIREMENT_MAPPING.md)

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Usage

```php
use ScratchBird\PDO\ScratchBirdPDO;

$pdo = new ScratchBirdPDO("scratchbird://user:pass@localhost:3092/mydb");
$stmt = $pdo->query("SELECT 1");
$row = $stmt->fetch();
```

## Connection strings

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```
