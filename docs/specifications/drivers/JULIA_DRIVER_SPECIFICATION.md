# Julia Driver Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support the ScratchBird Julia driver at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `LibPQ.jl`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/drivers/julia`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/julia/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_JULIA_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- The Julia lane must feel native to the Julia data ecosystem, not like a thin
  transport wrapper.
- The remaining work is intentionally reduced to `implementation_pending` plus
  `server_blocked` release proof.

## Mandatory Competitive Closure

- match or exceed `LibPQ.jl` for DBInterface-oriented usability
- provide deterministic `Tables.jl`/`DataFrames.jl` shaping
- preserve transaction, type, and error correctness comparable to JDBC/.NET where relevant

## Required Capability Families

- `DBInterface`-compatible connect/prepare/execute behavior
- parameter binding and typed result conversion
- transaction, rollback, and copy/import-export flows
- rowset materialization into `Tables.jl` and `DataFrames.jl`
- metadata and error behavior suitable for Julia users

## Required Packaging And Integration Surface

- Julia package layout and registry-ready packaging
- explicit supported Julia/runtime matrix
- release-evidence staging at `release/readiness/julia/<version>/`
- examples for `DBInterface`, `Tables.jl`, and `DataFrames.jl`

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `julia --project=. -e 'using Pkg; Pkg.instantiate()'`
2. contract and conformance: `julia --project=. -e 'using Pkg; Pkg.test()'`
3. performance: `julia --project=. benchmarks/run.jl`

## Implementation Sequence

1. connect/auth and `DBInterface` bootstrap
2. query/prepare/bind/fetch surface
3. transaction and copy flows
4. type and metadata coverage
5. package/release and example bundles

## Remaining Work Classification

### Implementation Pending

- implement the Julia driver package and `DBInterface` surface
- implement type conversion and result shaping
- implement metadata, error, and copy-path coverage

### Server Blocked

- validate `DataFrames.jl` shaping against a live server
- publish compatibility and performance evidence
- prove package/install behavior on supported Julia versions

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/julia.md`
- Getting started: `docs/getting-started/julia.md`
- Later verification packet: `docs/development/server-verification/julia.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

