# Python Driver

## Install

Local dev install:

```bash
python -m pip install -e python
```

## Quick Start

```python
import scratchbird

conn = scratchbird.connect(
    "scratchbird://user:pass@localhost:3092/mydb"
)
cur = conn.cursor()
cur.execute("SELECT 1 AS one")
print(cur.fetchone())
conn.close()
```

## Connection Strings

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```

See [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## TLS

TLS 1.3 is required. `sslmode=disable` is rejected.

## Parameters

The driver accepts positional sequences or named dict parameters. Named
parameters use `:name` placeholders in SQL.

```python
cur.execute("SELECT :v::INTEGER", {"v": 42})
```

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_TEST_DSN`
