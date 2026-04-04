# R2DBC Driver Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support the ScratchBird R2DBC driver at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `PostgreSQL R2DBC driver`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/drivers/r2dbc`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/r2dbc/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_R2DBC_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- Implementation must not be weaker than the current JDBC/.NET baseline where
  the host surface exposes equivalent capability families.
- The remaining work is now intentionally reduced to:
  - `implementation_pending`: build the native lane
  - `server_blocked`: collect live release evidence and performance proof

## Mandatory Competitive Closure

- match or exceed the PostgreSQL R2DBC baseline for Reactor and Spring-facing
  integration
- preserve JDBC/.NET-class correctness for transactions, metadata, errors, and
  type behavior where the reactive surface exposes equivalents
- provide deterministic backpressure, cancellation, and reconnect rules that
  remain consistent with ScratchBird MGA/session truth

## Required Capability Families

- `ConnectionFactory` and `ConnectionFactoryProvider` compatibility
- option parsing for host/user/password/database/TLS/session settings
- reactive `Connection`, `Statement`, `Batch`, and `Result` lifecycle
- prepared statements, parameter binding, batching, and generated-value flows
- transaction, savepoint, rollback-only, and autocommit compatibility
- row streaming with deterministic backpressure and cancellation behavior
- column, parameter, and server metadata surfaces expected by R2DBC consumers
- SQLSTATE/error mapping safe for Reactor and Spring integrations

## Required Packaging And Integration Surface

- Maven/Gradle-consumable Java package coordinates
- compatibility with `r2dbc-spi`, `r2dbc-pool`, and Spring Data R2DBC
- release-evidence staging at `release/readiness/r2dbc/<version>/`
- explicit supported JVM/runtime version matrix in the release evidence pack

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `./gradlew clean testClasses`
2. contract and conformance: `./gradlew test`
3. performance: `./gradlew jmh`

These commands become the authoritative later verification entry points for the
lane and must remain stable once implemented.

## Implementation Sequence

1. connection/auth/TLS and option parsing
2. reactive statement execution, bind, and result streaming
3. transaction/savepoint/cancel behavior
4. metadata/type/error coverage
5. pool and Spring-facing integration examples
6. release-evidence automation

## Remaining Work Classification

### Implementation Pending

- implement the native R2DBC transport/client lane
- implement metadata, type-codec, and error mapping tables
- implement Spring/pooling integration adapters and examples

### Server Blocked

- collect DSN-backed contract results
- publish compatibility and performance numbers
- validate backpressure/cancellation timing against a live server

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/r2dbc.md`
- Getting started: `docs/getting-started/r2dbc.md`
- Later verification packet: `docs/development/server-verification/r2dbc.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

