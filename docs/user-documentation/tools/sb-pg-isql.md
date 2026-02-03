# sb_pg_isql

PostgreSQL protocol script runner for testing ScratchBird's PostgreSQL emulation listener.

## Status

Baseline implementation available; depends on server-side emulation coverage.

## Synopsis

```
sb_pg_isql [OPTIONS] [DATABASE]
```

## Purpose

- Run PostgreSQL SQL scripts against ScratchBird's PostgreSQL listener
- Validate PostgreSQL client compatibility

## Notes

- Uses PostgreSQL protocol (default port 5432).
- Intended for parity and regression testing, not as a primary native client.
