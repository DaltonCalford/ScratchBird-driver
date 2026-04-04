# Metabase adapter Best-In-Class Selection

Date: 2026-04-03
Lane: `metabase`
Selected benchmark: `Metabase PostgreSQL driver`

## Selection Summary

The PostgreSQL driver is the strongest benchmark because it exercises the richest
combination of query builder, native SQL, sync, and field fingerprinting behavior in
Metabase.

## Candidate Pool

`Metabase PostgreSQL driver`, `Metabase MySQL driver`, `Metabase SQL Server driver`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Metabase PostgreSQL driver | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| Metabase MySQL driver | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| Metabase SQL Server driver | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The Metabase plugin is thin and aligned to JDBC behavior, but it is not yet benchmarked
against the strongest first-party Metabase database drivers. Schema sync, fingerprinting, and feature-flag behavior need first-class closure.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | Metabase databases docs | https://www.metabase.com/docs/latest/databases/start | downloaded |
| selected_repo | Metabase repo | https://github.com/metabase/metabase | downloaded |
| candidate_docs | Metabase PostgreSQL docs | https://www.metabase.com/docs/latest/databases/connections/postgresql | downloaded |
| candidate_docs | Metabase MySQL docs | https://www.metabase.com/docs/latest/databases/connections/mysql | downloaded |
| candidate_docs | Metabase SQL Server docs | https://www.metabase.com/docs/latest/databases/connections/sql-server | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
