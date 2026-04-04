# Python Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `psycopg3`
- Authoritative lane spec: `docs/specifications/drivers/language/python/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/python.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

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

## Cursor Re-execution

Reusing the same cursor for a new `execute()` call discards any unread rows and
pending protocol trailers from the previous statement. Fetch the remaining rows
or advance with `nextset()` before re-executing if the earlier results still
matter.

Statement errors are also synchronized before control returns to the caller.
After catching a `ProgrammingError` or other DB-API exception, the same
connection can issue `rollback()` and continue with a new `execute()` without
manual reconnect just to clear protocol state.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_TEST_DSN`
