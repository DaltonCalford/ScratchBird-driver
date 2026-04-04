# dbt Adapter API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `adapter`
- Current state: `planned_beta1`
- Best-in-class benchmark: `dbt-postgres`
- Authoritative lane spec: `docs/application-reference/DBT_ADAPTER_COMPATIBILITY_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/dbt/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_DBT_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but the adapter package and all live proof remain outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- `dbt-scratchbird` adapter package
- adapter plugin registration and connection manager
- release evidence root: `release/readiness/dbt/<version>/`

## Mandatory Integration Surface

- dbt-core adapter contract
- relation, quoting, schema naming, and type mapping
- materializations and incremental behavior
- seeds, snapshots, tests, docs, and relation caching

## Non-Optional Behaviors

- deterministic compatibility with ScratchBird transaction semantics
- no degradation relative to underlying JDBC/.NET-class capability families where they are traversed
- explicit handling of adapter/version compatibility

## Later Proof

- server verification packet: `docs/development/server-verification/dbt.md`
- release evidence root: `release/readiness/dbt/<version>/`

