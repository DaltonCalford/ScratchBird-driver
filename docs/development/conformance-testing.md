# Conformance Testing

The conformance harness validates protocol and type coverage against shared
fixtures and a manifest.

## Fixtures

- SQL fixtures: `docs/fixtures/core_fixture.sql`, `docs/fixtures/types_fixture.sql`
- Manifest: `docs/fixtures/sbwp_conformance_manifest.json`

See [DRIVER_CONFORMANCE_TEST_HARNESS.md](../specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md).

## Go Harness

The Go driver includes a harness runner:

```bash
cd go
SCRATCHBIRD_GO_URL="scratchbird://user:pass@localhost:3092/db" \
SCRATCHBIRD_CONFORMANCE_MANIFEST="../docs/fixtures/sbwp_conformance_manifest.json" \
go test ./conformance
```
