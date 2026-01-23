# Conformance Testing

The shared conformance harness validates protocol behavior and type coverage
using fixtures and a manifest.

- Harness spec: https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md
- Fixtures: https://github.com/DaltonCalford/ScratchBird-driver/tree/main/docs/fixtures

## Go Harness Example

```bash
cd go
SCRATCHBIRD_GO_URL="scratchbird://user:pass@localhost:3092/db" \
SCRATCHBIRD_CONFORMANCE_MANIFEST="../docs/fixtures/sbwp_conformance_manifest.json" \
go test ./conformance
```
