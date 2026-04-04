# Prisma adapter Best-In-Class Selection

Date: 2026-04-03
Lane: `prisma`
Selected benchmark: `Prisma PostgreSQL connector`

## Selection Summary

The PostgreSQL connector is the strongest Prisma benchmark because it receives the most
complete introspection, migration, and runtime coverage in the Prisma ecosystem.

## Candidate Pool

`Prisma PostgreSQL connector`, `Prisma MySQL connector`, `Prisma SQL Server connector`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Prisma PostgreSQL connector | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| Prisma MySQL connector | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| Prisma SQL Server connector | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The current lane is a deterministic scaffold, not yet a full provider runtime. Competitive closure has to be measured against official Prisma connectors, especially
PostgreSQL.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | Prisma PostgreSQL docs | https://www.prisma.io/docs/orm/overview/databases/postgresql | downloaded |
| selected_repo | Prisma repo | https://github.com/prisma/prisma | downloaded |
| candidate_docs | Prisma MySQL docs | https://www.prisma.io/docs/orm/overview/databases/mysql | downloaded |
| candidate_docs | Prisma SQL Server docs | https://www.prisma.io/docs/orm/overview/databases/sql-server | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
