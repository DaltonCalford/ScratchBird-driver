# Conformance Testing

The conformance harness validates protocol and type coverage against shared
fixtures and a manifest.

## Fixtures

- SQL fixtures: `docs/fixtures/core_fixture.sql`, `docs/fixtures/types_fixture.sql`
- Manifest: `docs/fixtures/sbwp_conformance_manifest.json`
- SQLSTATE contract: `docs/fixtures/sqlstate_required_set.json`
- Closure substrate: `docs/fixtures/driver_closure_substrate.json`

See [DRIVER_CONFORMANCE_TEST_HARNESS.md](../specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md).

## Runtime Setup Helper

Use the bundled runtime helper to start ScratchBird server/parser/listener and
load shared fixtures before running language-specific integration tests:

```bash
scripts/driver_runtime_stack.sh up
scripts/driver_runtime_stack.sh fixtures
eval "$(scripts/driver_runtime_stack.sh env)"
```

## Go Harness

The Go driver includes a harness runner:

```bash
cd tracks/alpha/drivers/go
SCRATCHBIRD_GO_URL="scratchbird://user:pass@localhost:3092/db" \
SCRATCHBIRD_CONFORMANCE_MANIFEST="../docs/fixtures/sbwp_conformance_manifest.json" \
go test ./conformance
```

Optional gating for long-running/cancel tests:

```bash
SCRATCHBIRD_CONFORMANCE_CANCEL=1
```

## Cross-Driver Closure Summaries

Normalize lane results into the shared PH5 closure substrate with:

```bash
python3 scripts/driver_closure_substrate.py summarize \
  --driver-id go \
  --lane alpha-primary \
  --conformance-results /path/to/go_conformance.json \
  --sqlstate-codes /path/to/go_sqlstates.json \
  --output /path/to/go_summary.json

python3 scripts/driver_closure_substrate.py matrix \
  --driver-summary /path/to/go_summary.json \
  --driver-summary /path/to/node_summary.json \
  --output-json /path/to/driver_matrix.json \
  --output-csv /path/to/driver_matrix.csv
```
