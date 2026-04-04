# R driver Best-In-Class Selection

Date: 2026-04-03
Lane: `r`
Selected benchmark: `RPostgres`

## Selection Summary

RPostgres is the strongest benchmark because it is the most mature DBI-native relational
driver with strong data frame integration and operational adoption.

## Candidate Pool

`RPostgres`, `RMariaDB`, `odbc`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| RPostgres | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| RMariaDB | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| odbc | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

Connection/auth coverage and richer metadata parity are still incomplete for the R lane. The target benchmark is the strongest DBI-native driver, not just any working wrapper.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | RPostgres docs | https://rpostgres.r-dbi.org/ | downloaded |
| selected_repo | RPostgres repo | https://github.com/r-dbi/RPostgres | downloaded |
| candidate_docs | RMariaDB docs | https://rmariadb.r-dbi.org/ | downloaded |
| candidate_docs | R odbc docs | https://odbc.r-dbi.org/ | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
