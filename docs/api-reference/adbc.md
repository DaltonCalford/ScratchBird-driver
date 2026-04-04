# ADBC / Arrow Driver API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `Apache Arrow ADBC PostgreSQL driver`
- Authoritative lane spec: `docs/specifications/drivers/ADBC_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/adbc/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_ADBC_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but the native driver, wrappers, and live evidence are still outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- native ADBC driver binary and headers
- driver-manager compatibility story
- release evidence root: `release/readiness/adbc/<version>/`

## Mandatory API Surface

- `AdbcDatabase`, `AdbcConnection`, and `AdbcStatement` lifecycle
- Arrow stream import/export
- bind, bulk ingest, and partition descriptors
- `GetInfo`, metadata, and schema operations
- stable ADBC status and error mapping

## Non-Optional Behaviors

- no forced row-materialization path for analytical export
- transaction and metadata behavior not weaker than the JDBC/.NET baseline for equivalent families
- explicit Arrow type mapping for ScratchBird-native and analytical types

## Later Proof

- server verification packet: `docs/development/server-verification/adbc.md`
- release evidence root: `release/readiness/adbc/<version>/`

