# Beta 1 Expansion R2DBC Gap Report

Status: Current
Lane: `r2dbc`
Benchmark: `PostgreSQL R2DBC driver`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/r2dbc/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no native `ConnectionFactory` provider or option parser exists yet
- no reactive connection, statement, batch, or result implementation exists
- no backpressure-aware result streaming or cancellation contract is proven
- no Spring Data / `r2dbc-pool` integration package exists yet

## Metadata And Type Gaps

- no reactive metadata bridge exists yet for column, parameter, or server info
- no lane-local type-codec table exists yet for JDBC/.NET-equivalent families
- no SQLSTATE-to-reactive error mapping is implemented yet

## Packaging And Tooling Gaps

- no Java artifact coordinates, BOM story, or release packaging exist yet
- no framework compatibility statement or sample app bundle exists yet
- no contract-test harness specialized for Reactor/R2DBC exists yet

## Live-Proof-Only Gaps

- transaction timing, cancellation timing, and backpressure need real-server proof
- pool integration and reconnect behavior need live validation
- performance and memory evidence must be measured against a working server

## Offline Closure Target

Offline closure is achieved when the lane spec, public docs, and verification
packet explicitly cover all benchmark-derived capability families and reduce the
remaining work to `implementation_pending` plus `server_blocked`.
