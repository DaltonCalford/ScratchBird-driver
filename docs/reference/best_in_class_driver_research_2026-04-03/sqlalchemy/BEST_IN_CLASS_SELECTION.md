# SQLAlchemy dialect Best-In-Class Selection

Date: 2026-04-03
Lane: `sqlalchemy`
Selected benchmark: `SQLAlchemy PostgreSQL dialect`

## Selection Summary

The PostgreSQL dialect is the strongest benchmark because it exercises the richest
reflection, DDL, ORM, and Alembic integration behavior in the mainstream SQLAlchemy
ecosystem.

## Candidate Pool

`SQLAlchemy PostgreSQL dialect`, `SQLAlchemy MySQL dialect`, `SQLAlchemy SQL Server dialect`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| SQLAlchemy PostgreSQL dialect | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| SQLAlchemy MySQL dialect | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| SQLAlchemy SQL Server dialect | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The dialect already reflects core metadata, but it is not yet benchmarked against the
strongest first-party SQLAlchemy dialects. Alembic, ORM lifecycle, reflection depth, and DDL behavior remain the main closure
areas.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | SQLAlchemy PostgreSQL dialect docs | https://docs.sqlalchemy.org/en/20/dialects/postgresql.html | downloaded |
| selected_repo | SQLAlchemy repo | https://github.com/sqlalchemy/sqlalchemy | downloaded |
| candidate_docs | SQLAlchemy MySQL dialect docs | https://docs.sqlalchemy.org/en/20/dialects/mysql.html | downloaded |
| candidate_docs | SQLAlchemy MSSQL dialect docs | https://docs.sqlalchemy.org/en/20/dialects/mssql.html | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
