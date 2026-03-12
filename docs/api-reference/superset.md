# Superset Driver API Reference

The Superset driver consists of:

- `scratchbird_superset.dialect.ScratchBirdDialect`
- `scratchbird_superset.engine_spec.ScratchBirdEngineSpec`

## SQLAlchemy Dialect

The dialect registers the `scratchbird://` scheme and delegates DB-API calls
to the ScratchBird Python driver. It implements schema/table/column/index
reflection using `sys.*` catalog views, normalizes JDBC-style DSN aliases such
as `currentSchema` and `searchPath` to the Python driver contract, and resolves
the default schema from the live session via `SHOW current_schema` with
`users.public` fallback.

## Engine Spec

The EngineSpec exposes ScratchBird capabilities, time grain expressions, and
metadata for Superset.

See `tracks/beta/integrations/scratchbird-superset-driver/scratchbird_superset/engine_spec.py` for the
canonical implementation.
