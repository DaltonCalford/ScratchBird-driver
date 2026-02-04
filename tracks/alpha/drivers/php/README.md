# ScratchBird PDO Driver (Userland)

Pure-PHP ScratchBird PDO-style driver using the native wire protocol.

## Documentation

- Getting started: `docs/getting-started/php.md`
- API reference: `docs/api-reference/php.md`

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

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
