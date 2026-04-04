# Hibernate dialect Best-In-Class Selection

Date: 2026-04-03
Lane: `hibernate`
Selected benchmark: `Hibernate PostgreSQLDialect`

## Selection Summary

The PostgreSQL dialect is the best benchmark because it exercises the widest practical
range of Hibernate ORM behavior while staying closest to ScratchBird’s relational
feature shape.

## Candidate Pool

`Hibernate PostgreSQLDialect`, `Hibernate SQLServerDialect`, `Hibernate MySQLDialect`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Hibernate PostgreSQLDialect | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| Hibernate SQLServerDialect | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| Hibernate MySQLDialect | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The lane currently proves deterministic contract helpers, not a full first-class
Hibernate runtime. Parity has to be judged against the strongest Hibernate dialects, especially PostgreSQL.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | Hibernate dialect docs | https://docs.jboss.org/hibernate/orm/current/dialect/dialect.html | downloaded |
| selected_repo | Hibernate ORM repo | https://github.com/hibernate/hibernate-orm | downloaded |
| candidate_docs | Hibernate user guide | https://docs.jboss.org/hibernate/orm/current/userguide/html_single/Hibernate_User_Guide.html | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
