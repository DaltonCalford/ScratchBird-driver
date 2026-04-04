# Julia Driver Best-In-Class Research

Status: Current
Lane: `julia`
Benchmark: `LibPQ.jl`

## Why This Benchmark

LibPQ.jl is the strongest open benchmark for Julia database connectivity into a
PostgreSQL-class system. It sets the expectation level for:

- `DBInterface.jl` integration
- `Tables.jl` and `DataFrames.jl` shaping
- prepared statements and parameter binding
- asynchronous execution helpers and copy flows

## Official Sources

- LibPQ.jl stable docs:
  `https://juliadatabases.org/LibPQ.jl/stable/`
- Implementation anchor:
  `https://github.com/JuliaDatabases/LibPQ.jl`

## Capability Families That Become Non-Optional

- `DBInterface`-compatible connect/prepare/execute flows
- rowset conversion into `Tables.jl`/`DataFrames.jl`
- typed parameter binding and result conversion
- transaction, error, and copy/import-export support
- Julia package ergonomics and artifact/distribution expectations

## ScratchBird Implementation Implications

- the lane must feel native in the Julia data ecosystem rather than like a thin
  C wrapper
- type conversion and null handling need to be deterministic for scientific and
  analytical users
- packaging needs to support Julia registry expectations and binary artifact
  strategy

## Later Server Validation Focus

- `DBInterface` conformance smoke tests
- `DataFrames.jl`/`Tables.jl` result shaping
- transaction and copy-path correctness
- package/install validation across supported Julia versions
