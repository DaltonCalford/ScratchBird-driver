# TypeORM adapter Best-In-Class Selection

Date: 2026-04-03
Lane: `typeorm`
Selected benchmark: `TypeORM PostgreSQL driver`

## Selection Summary

The PostgreSQL driver is the strongest TypeORM benchmark because it exercises the
deepest range of TypeORM schema, migration, relation, and query-builder behavior in
production use.

## Candidate Pool

`TypeORM PostgreSQL driver`, `TypeORM MySQL driver`, `TypeORM SQL Server driver`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| TypeORM PostgreSQL driver | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| TypeORM MySQL driver | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| TypeORM SQL Server driver | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The current TypeORM lane is a deterministic contract helper set, not yet a production-
grade adapter. Parity has to be judged against the official PostgreSQL TypeORM behavior, especially
schema sync and migrations.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | TypeORM PostgreSQL docs | https://typeorm.io/docs/drivers/postgres/ | downloaded |
| selected_repo | TypeORM repo | https://github.com/typeorm/typeorm | downloaded |
| candidate_docs | TypeORM MySQL docs | https://typeorm.io/docs/drivers/mysql/ | downloaded |
| candidate_docs | TypeORM SQL Server docs | https://typeorm.io/docs/drivers/microsoft-sqlserver/ | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
