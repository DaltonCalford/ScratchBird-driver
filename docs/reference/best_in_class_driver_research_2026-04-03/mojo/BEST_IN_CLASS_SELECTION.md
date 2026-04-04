# Mojo driver Best-In-Class Selection

Date: 2026-04-03
Lane: `mojo`
Selected benchmark: `Composite (asyncpg + pgx + PostgresNIO)`

## Selection Summary

A composite benchmark is the only defensible choice because the Mojo ecosystem does not
yet have a mature direct relational driver; the target bar must be assembled from the
best direct async drivers in adjacent ecosystems.

## Candidate Pool

`Composite (asyncpg + pgx + PostgresNIO)`, `asyncpg`, `pgx`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Composite (asyncpg + pgx + PostgresNIO) | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| asyncpg | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| pgx | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

Surface parity exists, but the lane still depends on a Python bridge and lacks full
native SBWP transport closure. No single mature Mojo benchmark exists, so the benchmark has to be composite.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | asyncpg docs | https://magicstack.github.io/asyncpg/current/ | downloaded |
| selected_repo | asyncpg repo | https://github.com/MagicStack/asyncpg | downloaded |
| candidate_docs | pgx docs | https://pkg.go.dev/github.com/jackc/pgx/v5 | downloaded |
| candidate_repo | PostgresNIO repo | https://github.com/vapor/postgres-nio | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
