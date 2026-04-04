# Hibernate dialect Implementation Anchors

Date: 2026-04-03
Lane: `hibernate`
Selected benchmark: `Hibernate PostgreSQLDialect`

## ScratchBird Current Truth Inputs

Current truth sources: README.md; examples/README.md;
docs/specifications/drivers/JDBC_DRIVER_SPECIFICATION.md;
docs/audit/DRIVER_IMPLEMENTATION_AUDIT.md

## Benchmark/Reference Anchors

- `Hibernate dialect docs`: https://docs.jboss.org/hibernate/orm/current/dialect/dialect.html
- `Hibernate ORM repo`: https://github.com/hibernate/hibernate-orm (`refs/heads/main b6a7117ad17f2032093581bb934b6e8b5050182f`)
- `Hibernate user guide`: https://docs.jboss.org/hibernate/orm/current/userguide/html_single/Hibernate_User_Guide.html

## Primary Competitive Closure Areas

- Move from deterministic dialect helpers to full schema tooling, DDL generation, and
entity lifecycle validation.
- Close pagination, locking, generated key, and type contribution gaps against the
strongest PostgreSQL dialect behavior.
- Add migration and integration-test evidence instead of relying only on contract-unit
coverage.

## Low-Reasoning-AI Implementation Flow

1. Read the lane README, baseline mapping or adapter contract, and the current lane spec.
2. Read the selected benchmark docs and repo anchors in this packet.
3. Compare each category in `COMPETITIVE_FEATURE_MATRIX.csv`.
4. Implement the missing categories in priority order: correctness first, then metadata/tooling, then packaging/performance evidence.
5. Re-run contract tests, conformance reports, compatibility matrices, and benchmark evidence before closing the lane.
