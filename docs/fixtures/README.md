# Driver Conformance Fixtures

This directory contains shared SQL fixtures used by the driver conformance
harness. The harness loads these fixtures before running tests so each driver
sees the same schema and seed data.

Planned files:

- `core_fixture.sql` - baseline schema + seed data for harness tests
- `types_fixture.sql` - per-type test data for one-way decode coverage
- `sbwp_conformance_manifest.json` - starter harness manifest
