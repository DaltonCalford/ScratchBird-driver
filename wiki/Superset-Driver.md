# Superset Driver

The Superset driver integrates ScratchBird with Apache Superset through a SQLAlchemy dialect.

## Install

```bash
pip install scratchbird-superset
```

## Enable in Superset

1. Install the package into the Superset Python environment
2. Restart Superset
3. Add a new database with a SQLAlchemy URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

## Configuration

| Parameter | Description |
|-----------|-------------|
| host | ScratchBird server hostname |
| port | Server port (default: 3092) |
| database | Database name |
| user | Username |
| password | Password |
| sslmode | TLS mode (require/verify-ca/verify-full) |

## Requirements

- Apache Superset 2.0+ (or compatible version)
- ScratchBird server with SBWP v1.1
- TLS 1.3 enabled (`sslmode=disable` is rejected)

## Components

The driver consists of:

- **ScratchBirdDialect** - SQLAlchemy dialect registering the `scratchbird://` scheme
- **ScratchBirdEngineSpec** - Superset engine specification for capabilities and time grains

## Metadata Support

The dialect implements schema/table/column reflection using `sys.*` catalog views:

- `get_pk_constraint` - Primary key discovery
- `get_foreign_keys` - Foreign key relationships
- `get_indexes` - Index information
- Type resolution via `sys.types`

## Troubleshooting

### Dialect Not Loading

Confirm the package entry points are registered:

```bash
python -c "from sqlalchemy.dialects import registry; print(registry.load('scratchbird'))"
```

Expected entry points:
- `sqlalchemy.dialects`: `scratchbird`
- `superset.db_engine_specs`: `scratchbird`

### Connection Failed

- Verify ScratchBird server is running on port 3092
- Check TLS is enabled (required)
- Verify credentials and database name

### Binary Transfer Errors

The dialect enforces `binary_transfer=true`. If you see SQLSTATE 0A000, ensure no client is overriding this setting.
