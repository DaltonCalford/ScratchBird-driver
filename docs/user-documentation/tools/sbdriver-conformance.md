# sbdriver-conformance

SBWP v1.1 conformance adapter used by the driver test harness.

## Status

Baseline implementation available; conformance suite continues to expand.

## Synopsis

```
sbdriver-conformance [--dsn <dsn>] [--manifest <file>] [--dsn-append <kv>]
```

## Purpose

- Executes the shared conformance manifest
- Emits machine-readable JSON results
- Validates protocol features and type coverage

## Notes

- Use with `docs/fixtures/sbwp_conformance_manifest.json`.
- Harness scripts are in `scripts/` for automation.
