# DBeaver integration Best-In-Class Selection

Date: 2026-04-03
Lane: `dbeaver`
Selected benchmark: `DBeaver PostgreSQL extension`

## Selection Summary

The PostgreSQL extension is the best benchmark because it exercises the broadest
metadata tree, DDL tooling, and general-purpose relational workflows in DBeaver’s own
plugin architecture.

## Candidate Pool

`DBeaver PostgreSQL extension`, `DBeaver MySQL extension`, `DBeaver SQL Server extension`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| DBeaver PostgreSQL extension | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| DBeaver MySQL extension | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| DBeaver SQL Server extension | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The current DBeaver work is a strong plugin scaffold plus a JDBC metadata compatibility
switch, but not yet a full first-class DBeaver integration surface. The lane needs richer navigator, editor, packaging, and update-site closure to compete
with first-party DBeaver extensions.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | DBeaver driver docs | https://dbeaver.com/docs/dbeaver/Database-drivers/ | downloaded |
| selected_repo | DBeaver PostgreSQL plugin | https://github.com/dbeaver/dbeaver/tree/devel/plugins/org.jkiss.dbeaver.ext.postgresql | downloaded |
| candidate_repo | DBeaver MySQL plugin | https://github.com/dbeaver/dbeaver/tree/devel/plugins/org.jkiss.dbeaver.ext.mysql | downloaded |
| candidate_repo | DBeaver SQL Server plugin | https://github.com/dbeaver/dbeaver/tree/devel/plugins/org.jkiss.dbeaver.ext.mssql | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
