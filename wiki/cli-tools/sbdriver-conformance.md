# sbdriver-conformance

SBWP v1.1 conformance adapter used by the driver test harness.

**Status:** Implemented (baseline)

## Synopsis

```
sbdriver-conformance [--dsn <dsn>] [--manifest <file>] [--dsn-append <kv>] [--binary-params|--text-params]
```

## Notes

- Reads `docs/fixtures/sbwp_conformance_manifest.json`.
- Emits JSON results for CI and audit tracking.
- Use `--binary-params` to send binary-encoded parameters (default is text).
