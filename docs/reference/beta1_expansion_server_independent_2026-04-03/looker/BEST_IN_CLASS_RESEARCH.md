# Looker Connector Best-In-Class Research

Status: Current
Lane: `looker`
Benchmark: `Looker PostgreSQL dialect`

## Why This Benchmark

The Looker PostgreSQL dialect defines the expectation set for what ScratchBird
must support to behave like a serious Looker target. It anchors:

- connection configuration and driver selection
- SQL generation and dialect expectations
- PDT-friendly DDL and persistence behavior
- metadata/type compatibility for LookML models and explores

## Official Sources

- Looker PostgreSQL configuration docs:
  `https://docs.cloud.google.com/looker/docs/db-config-postgresql`

## Capability Families That Become Non-Optional

- connection and credential configuration compatible with Looker expectations
- dialect-safe SQL, quoting, limit, and type behavior
- PDT-compatible DDL and temporary/persistent table workflows
- metadata and type fidelity for explores and SQL Runner
- deployment guidance for driver and credential packaging

## ScratchBird Implementation Implications

- this lane needs a first-class dialect contract, not just “works over JDBC”
- PDT behavior, temporary-object rules, and SQL generation compatibility must be
  explicit
- docs need to call out any capability that is delegated to the underlying
  driver versus implemented as Looker-specific behavior

## Later Server Validation Focus

- connection bootstrap and driver registration
- SQL Runner and explore query execution
- PDT creation/refresh flows
- dialect and type behavior under representative LookML workloads
