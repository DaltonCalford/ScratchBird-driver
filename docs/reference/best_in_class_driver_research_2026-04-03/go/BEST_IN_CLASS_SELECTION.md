# Go driver Best-In-Class Selection

Date: 2026-04-03
Lane: `go`
Selected benchmark: `pgx`

## Selection Summary

pgx is the strongest open benchmark for direct Go relational drivers because it balances
raw performance, correctness, typed APIs, and database/sql compatibility.

## Candidate Pool

`pgx`, `go-sql-driver/mysql`, `go-mssqldb`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| pgx | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| go-sql-driver/mysql | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| go-mssqldb | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The Go lane is already baseline complete and should be pushed toward best-in-class
ergonomics and performance proof. The core decision is to benchmark against pgx rather than a higher-level abstraction.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | pgx docs | https://pkg.go.dev/github.com/jackc/pgx/v5 | downloaded |
| selected_repo | pgx repo | https://github.com/jackc/pgx | downloaded |
| candidate_repo | go-sql-driver/mysql repo | https://github.com/go-sql-driver/mysql | downloaded |
| candidate_repo | go-mssqldb repo | https://github.com/microsoft/go-mssqldb | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
