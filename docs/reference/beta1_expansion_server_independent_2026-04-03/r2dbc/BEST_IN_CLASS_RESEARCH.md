# R2DBC Best-In-Class Research

Status: Current
Lane: `r2dbc`
Benchmark: `PostgreSQL R2DBC driver`

## Why This Benchmark

The PostgreSQL R2DBC driver is the clearest open benchmark for the Java
reactive database surface ScratchBird needs to support. It defines the
expectation set for:

- SPI-compliant `ConnectionFactory` integration
- Reactor-friendly reactive statement and result handling
- cancellation and backpressure semantics
- Spring Data / `r2dbc-pool` interoperability

## Official Sources

- R2DBC 1.0 specification:
  `https://r2dbc.io/spec/1.0.0.RELEASE/spec/html/`
- PostgreSQL R2DBC benchmark implementation:
  `https://github.com/pgjdbc/r2dbc-postgresql`

## Capability Families That Become Non-Optional

- `ConnectionFactory` discovery and option mapping
- reactive transaction and savepoint control
- bind markers, batching, and generated-value flows
- row streaming with deterministic backpressure behavior
- metadata and error surfaces consistent with JDBC/.NET-class expectations
- pooling and Spring-friendly configuration

## ScratchBird Implementation Implications

- the lane must preserve MGA transaction truth across async boundaries
- cancellation, timeout, and reconnect rules must be explicit rather than left
  to the reactive framework
- metadata and type coverage cannot be thinned merely because the host API is
  reactive

## Later Server Validation Focus

- contract tests for `ConnectionFactory`, transactions, bind, batch, and result
  streaming
- cancellation timing and backpressure behavior under load
- framework compatibility checks for Spring Data R2DBC and `r2dbc-pool`
