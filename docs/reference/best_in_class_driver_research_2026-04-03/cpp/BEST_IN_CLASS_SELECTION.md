# C/C++ driver Best-In-Class Selection

Date: 2026-04-03
Lane: `cpp`
Selected benchmark: `libpqxx`

## Selection Summary

libpqxx remains the strongest open direct relational C++ benchmark for transactional
correctness, typed result handling, prepared execution, and mature operational
documentation without hiding too much behind framework abstraction.

## Candidate Pool

`libpqxx`, `SOCI`, `nanodbc`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| libpqxx | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| SOCI | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| nanodbc | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

Lane-local baseline mapping already marks all JDBC/.NET parity groups implemented. Competitive closure is about raising polish, packaging, and benchmark-backed proof
rather than filling a baseline functional hole.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | libpqxx docs | https://libpqxx.readthedocs.io/stable/ | downloaded |
| selected_repo | libpqxx repo | https://github.com/jtv/libpqxx | downloaded |
| candidate_repo | SOCI repo | https://github.com/SOCI/soci | downloaded |
| candidate_docs | nanodbc docs | https://nanodbc.github.io/nanodbc/ | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
