# Driver Monitoring View Support

Status: Draft
Last Updated: 2026-01-29

## Purpose

Document the ScratchBird monitoring and diagnostics sys.* views that are now
exposed by the engine and define driver expectations for discovery and access.
This is supplemental to `METADATA_SCHEMA_CONTRACT.md` and focuses on runtime
observability tables rather than static metadata.

## Authoritative Sources

- `ScratchBird/docs/specifications/operations/MONITORING_SQL_VIEWS.md`
- `ScratchBird/docs/specifications/operations/MONITORING_DIALECT_MAPPINGS.md`
- `ScratchBird/docs/specifications/scheduler/SCHEDULER_JOB_RUNNER_CANONICAL_SPEC.md`
- Engine implementation: `ScratchBird/src/catalog/sys_catalog.cpp`

## Implemented sys.* Monitoring Views (Alpha)

These views are implemented as virtual tables in the engine and must be queryable
by all drivers without special casing.

| sys.* view | Purpose | Notes |
| --- | --- | --- |
| sys.sessions | Live session/connection state | See MONITORING_SQL_VIEWS.md section 1 |
| sys.context_variables | Session/transaction context variables | Used by language guide + trigger contexts |
| sys.transactions | Active/recent transaction state | See MONITORING_SQL_VIEWS.md section 2 |
| sys.locks | Lock inventory | See MONITORING_SQL_VIEWS.md section 3 |
| sys.statements | Active statements | See MONITORING_SQL_VIEWS.md section 4 |
| sys.io_stats | Per-session/txn/stmt IO counters | See MONITORING_SQL_VIEWS.md section 7 |
| sys.performance | Aggregate counters (key/value) | See MONITORING_SQL_VIEWS.md section 5 |
| sys.jobs | Job definitions | Scheduler spec section 6 |
| sys.job_runs | Job execution history | Scheduler spec section 6 |
| sys.job_dependencies | Job dependency edges | Scheduler spec section 6 |

## Spec-Defined But Not Yet Implemented (Track as Gaps)

These are defined in specs but are not currently exposed by sys_catalog.
Drivers should treat them as planned and avoid hard dependencies until the
engine exposes them.

| sys.* view | Spec Reference | Status |
| --- | --- | --- |
| sys.table_stats | MONITORING_SQL_VIEWS.md section 6 | Not implemented in sys_catalog.cpp |
| sys.tablespace_migrations | MONITORING_SQL_VIEWS.md section 8 | Beta |
| sys.shard_migrations | MONITORING_SQL_VIEWS.md section 9 | Beta/Cluster |
| sys.cache_stats | CACHE_AND_BUFFER_ARCHITECTURE.md | Not implemented in sys_catalog.cpp |
| sys.buffer_pool_stats | CACHE_AND_BUFFER_ARCHITECTURE.md | Not implemented in sys_catalog.cpp |
| sys.statement_cache | CACHE_AND_BUFFER_ARCHITECTURE.md | Not implemented in sys_catalog.cpp |

## Driver Expectations

### General

- Do not hide the `sys` schema or filter out sys.* views.
- Treat sys.* monitoring objects as read-only system views.
- Enforce binary-only transfer as required by SBWP v1.1.
- Do not attempt to filter rows for permissions; the engine enforces visibility.

### JDBC/ODBC Metadata

- getTables/SQLTables should include sys.* views as `SYSTEM VIEW`.
- getColumns/SQLColumns should surface all sys.* column names and types.
- getSchemas should include `sys`.

### SQLAlchemy Dialects (Superset, future tools)

- Reflect sys.* views when enumerating schemas/tables.
- Allow direct SQL queries against sys.* without rewriting.

### Helper APIs (optional)

If a driver provides a metadata helper layer, add convenience functions for:

- listSessions() -> sys.sessions
- listLocks() -> sys.locks
- listStatements() -> sys.statements
- listTransactions() -> sys.transactions
- getPerformanceMetrics() -> sys.performance
- listJobs() / listJobRuns() -> sys.jobs/sys.job_runs

## Security Notes

Monitoring views are subject to server-side visibility rules. Drivers must not
attempt to enforce row-level filtering. Use the engine’s authz behavior and
propagate any permission errors to the client.
