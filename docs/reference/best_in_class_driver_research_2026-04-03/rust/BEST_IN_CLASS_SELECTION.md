# Rust driver Best-In-Class Selection

Date: 2026-04-03
Lane: `rust`
Selected benchmark: `tokio-postgres`

## Selection Summary

tokio-postgres is the strongest direct-driver benchmark because it is a low-level, high-
quality async relational client with broad ecosystem adoption and robust
type/transaction semantics.

## Candidate Pool

`tokio-postgres`, `sqlx`, `mysql_async`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| tokio-postgres | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| sqlx | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| mysql_async | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The Rust lane is already strong, but it still needs benchmark-backed proof and ecosystem
integration closure. The benchmark should stay on direct async drivers, not just higher-level wrappers.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | tokio-postgres docs | https://docs.rs/tokio-postgres/latest/tokio_postgres/ | downloaded |
| selected_repo | rust-postgres repo | https://github.com/sfackler/rust-postgres | downloaded |
| candidate_docs | sqlx docs | https://docs.rs/sqlx/latest/sqlx/ | downloaded |
| candidate_docs | mysql_async docs | https://docs.rs/mysql_async/latest/mysql_async/ | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
