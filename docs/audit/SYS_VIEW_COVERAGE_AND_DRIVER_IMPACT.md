# sys.* Monitoring View Coverage and Driver Impact

Status: Draft
Last Updated: 2026-01-29

## Scope

Audit the ScratchBird engine’s sys.* monitoring/diagnostic views and summarize
what drivers must expose for metadata and tooling support.

## Sources of Truth

- Engine implementation: `ScratchBird/src/catalog/sys_catalog.cpp`
- Monitoring spec: `ScratchBird/docs/specifications/operations/MONITORING_SQL_VIEWS.md`
- Scheduler spec: `ScratchBird/docs/specifications/scheduler/SCHEDULER_JOB_RUNNER_CANONICAL_SPEC.md`
- Driver metadata mapping: `docs/specifications/DRIVER_METADATA_JDBC_ODBC_MAPPING.md`

## Implemented in Engine (Verified)

Verified against `ScratchBird/src/catalog/sys_catalog.cpp`:

| sys.* view | Evidence | Status | Driver impact |
| --- | --- | --- | --- |
| sys.sessions | Table list + column defs at `ScratchBird/src/catalog/sys_catalog.cpp:164` and `:240` | Implemented | Expose as SYSTEM VIEW; no driver filtering |
| sys.context_variables | Column defs at `ScratchBird/src/catalog/sys_catalog.cpp:262` | Implemented | Expose as SYSTEM VIEW |
| sys.transactions | Column defs at `ScratchBird/src/catalog/sys_catalog.cpp:268` | Implemented | Expose as SYSTEM VIEW |
| sys.locks | Column defs at `ScratchBird/src/catalog/sys_catalog.cpp:281` | Implemented | Expose as SYSTEM VIEW |
| sys.statements | Column defs at `ScratchBird/src/catalog/sys_catalog.cpp:298` | Implemented | Expose as SYSTEM VIEW |
| sys.io_stats | Column defs at `ScratchBird/src/catalog/sys_catalog.cpp:310` | Implemented | Expose as SYSTEM VIEW |
| sys.performance | Column defs at `ScratchBird/src/catalog/sys_catalog.cpp:231` | Implemented | Expose as SYSTEM VIEW |
| sys.jobs | Column defs at `ScratchBird/src/catalog/sys_catalog.cpp:181` | Implemented | Expose as SYSTEM VIEW |
| sys.job_runs | Column defs at `ScratchBird/src/catalog/sys_catalog.cpp:210` | Implemented | Expose as SYSTEM VIEW |
| sys.job_dependencies | Column defs at `ScratchBird/src/catalog/sys_catalog.cpp:226` | Implemented | Expose as SYSTEM VIEW |

## Spec-Defined But Missing in Engine

| sys.* view | Spec reference | Status | Driver impact |
| --- | --- | --- | --- |
| sys.table_stats | MONITORING_SQL_VIEWS.md section 6 | Not implemented in sys_catalog.cpp | Do not rely on this view yet |
| sys.tablespace_migrations | MONITORING_SQL_VIEWS.md section 8 | Beta | No driver work for Alpha |
| sys.shard_migrations | MONITORING_SQL_VIEWS.md section 9 | Beta | No driver work for Alpha |
| sys.cache_stats | CACHE_AND_BUFFER_ARCHITECTURE.md | Not implemented in sys_catalog.cpp | Planned |
| sys.buffer_pool_stats | CACHE_AND_BUFFER_ARCHITECTURE.md | Not implemented in sys_catalog.cpp | Planned |
| sys.statement_cache | CACHE_AND_BUFFER_ARCHITECTURE.md | Not implemented in sys_catalog.cpp | Planned |

## Driver Status Snapshot

- JDBC DatabaseMetaData is stubbed (getTables/getSchemas/getColumns return empty). This blocks
  all sys.* view discovery via metadata APIs.
- SQLAlchemy dialects (Superset) can query sys.* directly but do not yet join sys.types for
  full type names.
- Other language drivers allow raw SQL; no helper APIs yet.

## Recommended Driver Actions

1. JDBC/ODBC metadata: include sys.* views as `SYSTEM VIEW` and expose columns.
2. Optional helper APIs for monitoring queries (sessions/locks/statements/jobs).
3. Update driver docs to reflect sys.* monitoring availability and read-only nature.

