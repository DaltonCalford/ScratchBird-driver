# .NET driver Best-In-Class Selection

Date: 2026-04-03
Lane: `dotnet`
Selected benchmark: `Npgsql`

## Selection Summary

Npgsql is the strongest open ADO.NET benchmark because it combines provider
completeness, excellent performance, broad tooling support, and mature operational
documentation.

## Candidate Pool

`Npgsql`, `Microsoft.Data.SqlClient`, `MySqlConnector`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Npgsql | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| Microsoft.Data.SqlClient | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| MySqlConnector | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The lane is already at full baseline parity and should be treated as a flagship
provider. Competitive closure is about exceeding Npgsql-level release quality, diagnostics, and
ecosystem polish.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | Npgsql docs | https://www.npgsql.org/doc/index.html | downloaded |
| selected_repo | Npgsql repo | https://github.com/npgsql/npgsql | downloaded |
| candidate_docs | Microsoft.Data.SqlClient docs | https://learn.microsoft.com/en-us/sql/connect/ado-net/introduction-microsoft-data-sqlclient-namespace?view=sql-server-ver17 | downloaded |
| candidate_repo | MySqlConnector repo | https://github.com/mysql-net/MySqlConnector | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
