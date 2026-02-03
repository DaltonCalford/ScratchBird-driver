# sb_fb_isql

Firebird protocol script runner for testing ScratchBird's Firebird emulation listener.

## Status

Baseline implementation available; depends on server-side emulation coverage.

## Synopsis

```
sb_fb_isql [OPTIONS] [DATABASE]
```

## Purpose

- Run Firebird SQL scripts against ScratchBird's Firebird listener
- Validate Firebird client compatibility

## Notes

- Uses Firebird protocol (default port 3050).
- Intended for parity and regression testing, not as a primary native client.
