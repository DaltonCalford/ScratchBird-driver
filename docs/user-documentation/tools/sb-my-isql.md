# sb_my_isql

MySQL protocol script runner for testing ScratchBird's MySQL emulation listener.

## Status

Baseline implementation available; depends on server-side emulation coverage.

## Synopsis

```
sb_my_isql [OPTIONS] [DATABASE]
```

## Purpose

- Run MySQL SQL scripts against ScratchBird's MySQL listener
- Validate MySQL client compatibility

## Notes

- Uses MySQL protocol (default port 3306).
- Intended for parity and regression testing, not as a primary native client.
