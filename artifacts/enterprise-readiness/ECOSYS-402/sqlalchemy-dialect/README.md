# SQLAlchemy Dialect Artifact

Authoritative implementation now lives at:

- `tracks/alpha/integrations/scratchbird-sqlalchemy-dialect`

This artifact folder is retained for enterprise-readiness evidence and run logs.

Current implemented scope:

- standalone SQLAlchemy dialect package metadata (`pyproject.toml`)
- dialect reflection support for schemas/tables/views/columns/PK/FK/indexes
- reflection-key contract (`name`, `type`, `nullable`, `default`, `autoincrement`)
- schema-qualified reflection behavior
- deterministic dialect contract tests
- deterministic ORM flow example (`examples/orm_flow_example.py`)

Remaining scope (env/live integration):

- live SQLAlchemy engine/ORM session + transaction integration against runtime DSN
- runtime probe script:
  - `artifacts/enterprise-readiness/ECOSYS-402/verification_sqlalchemy_runtime_probe.sh`
- runtime attempt blocker evidence:
  - `artifacts/enterprise-readiness/ECOSYS-402/runtime_tls_blocker_2026-03-04.md`
