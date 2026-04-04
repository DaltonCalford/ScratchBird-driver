# Application Driver Specifications

Authoritative compatibility contracts for the active BI/application adapters in
the Beta 1 driver program.

Planned Beta 1 adapter lanes now have benchmark research packets, lane-local
gap reports, deepened authoritative compatibility specs, and deterministic
later verification packets in place before implementation.

## Adapter Status

| Adapter | Current State | Benchmark |
| --- | --- | --- |
| `dbeaver` | `partial_plugin` | `DBeaver PostgreSQL extension` |
| `dbt` | `planned_beta1` | `dbt-postgres` |
| `hibernate` | `partial_contract_only` | `Hibernate PostgreSQLDialect` |
| `airbyte` | `planned_beta1` | `Airbyte PostgreSQL source/destination` |
| `looker` | `planned_beta1` | `Looker PostgreSQL dialect` |
| `metabase` | `partial_adapter` | `Metabase PostgreSQL driver` |
| `powerbi` | `planned_beta1` | `Power BI PostgreSQL / ODBC custom connector surface` |
| `prisma` | `partial_contract_only` | `Prisma PostgreSQL connector` |
| `sqlalchemy` | `partial_adapter` | `SQLAlchemy PostgreSQL dialect` |
| `superset` | `partial_adapter` | `Superset PostgreSQL engine spec` |
| `tableau` | `planned_beta1` | `Tableau PostgreSQL / Named Connector SDK` |
| `typeorm` | `partial_contract_only` | `TypeORM PostgreSQL driver` |

## Authoritative Specs

- [DBeaver Extension](DBEAVER_COMPATIBILITY_SPECIFICATION.md)
- [dbt Adapter](DBT_ADAPTER_COMPATIBILITY_SPECIFICATION.md)
- [Airbyte Connector](AIRBYTE_CONNECTOR_COMPATIBILITY_SPECIFICATION.md)
- [Hibernate Dialect](HIBERNATE_COMPATIBILITY_SPECIFICATION.md)
- [Looker Connector](LOOKER_COMPATIBILITY_SPECIFICATION.md)
- [Metabase Plugin](METABASE_COMPATIBILITY_SPECIFICATION.md)
- [Power BI Connector](POWERBI_COMPATIBILITY_SPECIFICATION.md)
- [Prisma Adapter](PRISMA_COMPATIBILITY_SPECIFICATION.md)
- [SQLAlchemy Dialect](SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md)
- [Superset Driver](SUPERSET_COMPATIBILITY_SPECIFICATION.md)
- [Tableau Connector](TABLEAU_COMPATIBILITY_SPECIFICATION.md)
- [TypeORM Adapter](TYPEORM_COMPATIBILITY_SPECIFICATION.md)

## Notes

- Older draft pages under `docs/specifications/integrations/` are supporting
  template material or explicitly superseded for these targeted adapters.
- Live verification for these adapters is tracked in
  `docs/development/server-verification/`.
- Remaining implementation-pending and live-only work for the new adapter lanes
  is tracked in
  `docs/audit/DRIVER_BETA1_EXPANSION_SERVER_INDEPENDENT_REMAINING_WORK.md`.
