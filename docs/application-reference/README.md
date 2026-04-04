# Application Driver Specifications

Authoritative compatibility contracts for the active BI/application adapters in
the Beta 1 driver program.

## Adapter Status

| Adapter | Current State | Benchmark |
| --- | --- | --- |
| `dbeaver` | `partial_plugin` | `DBeaver PostgreSQL extension` |
| `hibernate` | `partial_contract_only` | `Hibernate PostgreSQLDialect` |
| `metabase` | `partial_adapter` | `Metabase PostgreSQL driver` |
| `prisma` | `partial_contract_only` | `Prisma PostgreSQL connector` |
| `sqlalchemy` | `partial_adapter` | `SQLAlchemy PostgreSQL dialect` |
| `superset` | `partial_adapter` | `Superset PostgreSQL engine spec` |
| `typeorm` | `partial_contract_only` | `TypeORM PostgreSQL driver` |

## Authoritative Specs

- [DBeaver Extension](DBEAVER_COMPATIBILITY_SPECIFICATION.md)
- [Hibernate Dialect](HIBERNATE_COMPATIBILITY_SPECIFICATION.md)
- [Metabase Plugin](METABASE_COMPATIBILITY_SPECIFICATION.md)
- [Prisma Adapter](PRISMA_COMPATIBILITY_SPECIFICATION.md)
- [SQLAlchemy Dialect](SQLALCHEMY_COMPATIBILITY_SPECIFICATION.md)
- [Superset Driver](SUPERSET_COMPATIBILITY_SPECIFICATION.md)
- [TypeORM Adapter](TYPEORM_COMPATIBILITY_SPECIFICATION.md)

## Notes

- Older draft pages under `docs/specifications/integrations/` are supporting
  template material or explicitly superseded for these targeted adapters.
- Live verification for these adapters is tracked in
  `docs/development/server-verification/`.
