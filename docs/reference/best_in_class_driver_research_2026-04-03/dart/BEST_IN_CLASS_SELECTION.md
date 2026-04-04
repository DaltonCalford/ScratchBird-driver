# Dart driver Best-In-Class Selection

Date: 2026-04-03
Lane: `dart`
Selected benchmark: `postgres (Dart)`

## Selection Summary

The Dart `postgres` package remains the best direct benchmark because it is the most
feature-rich, idiomatic async relational client in the Dart ecosystem with mature
statement, transaction, and stream handling.

## Candidate Pool

`postgres (Dart)`, `mysql1`, `sqlite3`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| postgres (Dart) | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| mysql1 | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| sqlite3 | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

Current audit still shows TXN, EXEC, META, TYPE, ERR, and RES gaps against the JDBC/.NET
baseline. The lane already has a strong async foundation but lacks full competitive closure around
metadata, live failure-path proof, and richer type coverage.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | pub.dev postgres | https://pub.dev/packages/postgres | downloaded |
| selected_repo | postgresql-dart repo | https://github.com/isoos/postgresql-dart | downloaded |
| candidate_docs | mysql1 package | https://pub.dev/packages/mysql1 | downloaded |
| candidate_docs | sqlite3 package | https://pub.dev/packages/sqlite3 | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
