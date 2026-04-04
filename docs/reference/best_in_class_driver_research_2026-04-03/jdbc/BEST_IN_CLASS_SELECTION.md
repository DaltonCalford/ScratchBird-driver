# JDBC driver Best-In-Class Selection

Date: 2026-04-03
Lane: `jdbc`
Selected benchmark: `pgjdbc`

## Selection Summary

pgjdbc remains the strongest open JDBC benchmark because of its DatabaseMetaData
breadth, protocol maturity, batching and copy behavior, and extensive framework
compatibility.

## Candidate Pool

`pgjdbc`, `MySQL Connector/J`, `Microsoft JDBC Driver for SQL Server`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| pgjdbc | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| MySQL Connector/J | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| Microsoft JDBC Driver for SQL Server | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The JDBC lane is already a flagship surface and should be judged against pgjdbc rather
than minimal connector parity. Closure is now about metadata depth, release evidence, packaging, and ecosystem polish.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | pgjdbc docs | https://jdbc.postgresql.org/documentation/ | downloaded |
| selected_repo | pgjdbc repo | https://github.com/pgjdbc/pgjdbc | downloaded |
| candidate_repo | Connector/J repo | https://github.com/mysql/mysql-connector-j | downloaded |
| candidate_docs | Microsoft JDBC docs | https://learn.microsoft.com/en-us/sql/connect/jdbc/overview-of-the-jdbc-driver?view=sql-server-ver17 | downloaded |
| candidate_repo | mssql-jdbc repo | https://github.com/microsoft/mssql-jdbc | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
