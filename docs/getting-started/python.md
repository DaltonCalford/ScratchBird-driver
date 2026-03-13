# Python Driver

## Install

For repo-local development:

```bash
cd tracks/p3/drivers/python
python -m pip install -e ".[test]"
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
- Auth-plugin startup keys are supported:
  `client_flags|connect_client_flags`, `auth_method_payload`,
  `auth_required_methods`, `auth_forbidden_methods`,
  `auth_require_channel_binding`, `workload_identity_token`, and
  `proxy_principal_assertion`.

## Parameters

The driver accepts positional sequences or named dict parameters. Named
parameters use `:name` placeholders in SQL.

```python
cur.execute("SELECT :v::INTEGER", {"v": 42})
```

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_TEST_DSN`
