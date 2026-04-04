# ODBC driver Best-In-Class Selection

Date: 2026-04-03
Lane: `odbc`
Selected benchmark: `Microsoft ODBC Driver for SQL Server`

## Selection Summary

The Microsoft driver is still the de facto best-in-class ODBC benchmark for metadata,
diagnostics, packaging, and platform support, but ScratchBird needs an open-source
anchor from psqlODBC for implementation structure.

## Candidate Pool

`Microsoft ODBC Driver for SQL Server`, `psqlODBC`, `MySQL Connector/ODBC`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Microsoft ODBC Driver for SQL Server | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| psqlODBC | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| MySQL Connector/ODBC | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The core ODBC lane is close, but metadata breadth and richer catalog surfaces still
trail stronger ODBC implementations. The benchmark must account for a closed commercial leader with an open-source
implementation anchor.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | Microsoft ODBC docs | https://learn.microsoft.com/en-us/sql/connect/odbc/microsoft-odbc-driver-for-sql-server | downloaded |
| anchor_docs | psqlODBC project | https://odbc.postgresql.org/ | downloaded |
| anchor_repo | psqlODBC repo | https://github.com/postgresql-interfaces/psqlodbc | downloaded |
| candidate_repo | MySQL Connector/ODBC repo | https://github.com/mysql/mysql-connector-odbc | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
