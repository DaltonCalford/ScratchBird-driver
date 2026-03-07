# Apache Superset Driver

ScratchBird integrates with Apache Superset through the SQLAlchemy dialect and
EngineSpec shipped in `scratchbird-superset`.

## Install

```bash
pip install scratchbird-superset
```

## Enable In Superset

1. Install the package into the Superset Python environment.
2. Restart Superset.
3. Add a new database with a SQLAlchemy URI such as:

```
scratchbird://user:password@host:3092/database?sslmode=prefer
```

Manager-proxy example:

```
scratchbird://user:password@host:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

Because the Superset adapter rides on the Python driver, the same parity DSN
features are available here, including `sslmode=disable` for explicit plaintext
development paths and `compression=zstd|none|off`.

Use TLS-enabled modes in production.

## Debugging

If the dialect does not load, confirm the package entry points:

- `sqlalchemy.dialects`: `scratchbird`
- `superset.db_engine_specs`: `scratchbird`

See `tracks/beta/integrations/scratchbird-superset-driver/README.md` for
scaffold details.
