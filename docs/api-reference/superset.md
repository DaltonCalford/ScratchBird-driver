# Superset Driver API Reference

The Superset driver consists of:

- `scratchbird_superset.dialect.ScratchBirdDialect`
- `scratchbird_superset.engine_spec.ScratchBirdEngineSpec`

## SQLAlchemy Dialect

The dialect registers the `scratchbird://` scheme and delegates DB-API calls
to the ScratchBird Python driver. It implements schema/table/column reflection
using `sys.*` catalog views.

## Engine Spec

The EngineSpec exposes ScratchBird capabilities, time grain expressions, and
metadata for Superset.

See `scratchbird-superset-driver/scratchbird_superset/engine_spec.py` for the
canonical implementation.
