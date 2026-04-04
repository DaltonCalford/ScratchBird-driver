# Beta 1 Expansion Julia Gap Report

Status: Current
Lane: `julia`
Benchmark: `LibPQ.jl`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/julia/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no `DBInterface.jl` driver implementation exists yet
- no typed query, prepare, transaction, or copy path exists yet
- no `Tables.jl` / `DataFrames.jl` shaping path exists yet

## Metadata And Type Gaps

- no Julia type-mapping table exists yet
- no metadata/introspection contract exists for Julia consumers
- no lane-local error and null-handling rules exist in code or tests

## Packaging And Tooling Gaps

- no Julia package structure, artifact plan, or registry publication plan exists yet
- no examples exist for common Julia data workflows
- no Julia-specific contract-test lane exists yet

## Live-Proof-Only Gaps

- transaction, copy, and async behavior need live validation
- DataFrame/result shaping needs proof against a running server
- packaging/install proof must be done on supported Julia versions

## Offline Closure Target

Offline closure is achieved when the Julia lane docs explicitly define the
package contract, DBInterface surface, type behavior, and later proof commands.
