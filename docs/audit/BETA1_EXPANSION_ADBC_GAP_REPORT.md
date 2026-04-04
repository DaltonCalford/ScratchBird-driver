# Beta 1 Expansion ADBC Gap Report

Status: Current
Lane: `adbc`
Benchmark: `Apache Arrow ADBC PostgreSQL driver`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/adbc/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no native ADBC `Database` / `Connection` / `Statement` implementation exists
- no Arrow-native export/import path is wired through a dedicated driver lane
- no bulk-ingest, partitioned-read, or `GetInfo` implementation exists yet

## Metadata And Type Gaps

- no lane-local ADBC metadata bridge exists yet
- no ADBC status/error mapping has been specified in code or tests
- no Arrow type-mapping table for ScratchBird-native types exists yet

## Packaging And Tooling Gaps

- no distributable ADBC C driver or driver-manager registration flow exists yet
- no language-wrapper guidance exists for Python/Go/Rust consumers
- no benchmark/perf harness exists for Arrow-native transport

## Live-Proof-Only Gaps

- zero-copy export claims require live proof
- bulk-ingest and partitioned-read throughput must be measured live
- driver-manager interoperability must be proven with a working server

## Offline Closure Target

Offline closure is achieved when the lane spec and public docs fully spell out
the ADBC capability contract, type rules, packaging targets, and later proof
steps so the remaining work is only implementation plus live validation.
