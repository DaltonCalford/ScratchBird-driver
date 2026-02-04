# ScratchBird Superset Driver

This package provides the ScratchBird SQLAlchemy dialect plus a Superset
DB engine spec. It enables Apache Superset to connect to ScratchBird using
SBWP v1.1 on the native port (3092).

## Install

From the repo root:

```bash
pip install -e scratchbird-superset-driver
```

Or install the published package once available:

```bash
pip install scratchbird-superset
```

## Superset Setup

1. Install this package into the Superset Python environment.
2. Restart Superset.
3. Add a new database using a SQLAlchemy URI like:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Notes:
- TLS is required; do not use `sslmode=disable`.
- Default port is 3092.
- `binary_transfer=true` is recommended (binary-only protocol).

## Development

- Entry points are registered for:
  - `sqlalchemy.dialects` (dialect name: `scratchbird`)
  - `superset.db_engine_specs` (engine spec: `ScratchBirdEngineSpec`)

The dialect delegates DB-API calls to the ScratchBird Python driver.

## References

- ScratchBird driver specs: `docs/specifications/`
- Superset integration spec: `docs/application-reference/SUPERSET_COMPATIBILITY_SPECIFICATION.md`
