# dbt Adapter Best-In-Class Research

Status: Current
Lane: `dbt`
Benchmark: `dbt-postgres`

## Why This Benchmark

`dbt-postgres` is the natural benchmark because it defines the mainstream dbt
adapter expectations for:

- adapter plugin contract behavior
- relation, quoting, and schema naming rules
- materializations and incremental strategies
- snapshots, seeds, tests, docs generation, and adapter packaging

## Official Sources

- PostgreSQL setup docs:
  `https://docs.getdbt.com/docs/local/connect-data-platform/postgres-setup`
- Adapter creation guide:
  `https://docs.getdbt.com/guides/adapter-creation`
- Implementation anchor:
  `https://github.com/dbt-labs/dbt-postgres`

## Capability Families That Become Non-Optional

- dbt-core adapter contract compatibility
- materializations for table, view, incremental, and ephemeral models
- snapshots, seeds, tests, and docs/introspection behavior
- relation caching, quoting, schema naming, and macro dispatch
- package/release structure expected by dbt users

## ScratchBird Implementation Implications

- the adapter must provide real dbt ergonomics, not just generic SQL execution
- the adapter needs deterministic compatibility with ScratchBird transactional
  semantics and naming rules
- packaging and CI expectations are part of the benchmark, not optional polish

## Later Server Validation Focus

- dbt-core integration runs across materializations
- snapshots, seeds, tests, and docs generation
- quoting and naming behavior in multi-schema scenarios
- adapter package install and version-compatibility proof
