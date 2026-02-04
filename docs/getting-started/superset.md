# Apache Superset Driver

ScratchBird integrates with Apache Superset through a SQLAlchemy dialect and
Superset EngineSpec shipped in `scratchbird-superset`.

## Install

```bash
pip install scratchbird-superset
```

## Enable in Superset

1. Install the package into the Superset Python environment.
2. Restart Superset.
3. Add a new database with a SQLAlchemy URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Notes:
- TLS is required; `sslmode=disable` is not allowed.
- Default port is 3092.
- `binary_transfer=true` is recommended for SBWP v1.1.

## Debugging

If the dialect does not load, confirm the package entry points:

- `sqlalchemy.dialects`: `scratchbird`
- `superset.db_engine_specs`: `scratchbird`

See `tracks/beta/integrations/scratchbird-superset-driver/README.md` for scaffold details.
