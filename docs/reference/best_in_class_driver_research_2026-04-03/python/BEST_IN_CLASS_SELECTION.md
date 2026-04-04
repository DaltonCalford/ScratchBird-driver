# Python driver Best-In-Class Selection

Date: 2026-04-03
Lane: `python`
Selected benchmark: `psycopg3`

## Selection Summary

psycopg3 is still the best benchmark because it combines DB-API correctness, advanced
type adaptation, async support, and mature operational documentation.

## Candidate Pool

`psycopg3`, `asyncpg`, `mysqlclient`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| psycopg3 | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| asyncpg | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| mysqlclient | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The Python lane is already strong and should be compared to psycopg3 rather than only
baseline DB-API compliance. Closure is about packaging, async posture, docs, and benchmark evidence.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | psycopg3 docs | https://www.psycopg.org/psycopg3/docs/ | downloaded |
| selected_repo | psycopg repo | https://github.com/psycopg/psycopg | downloaded |
| candidate_docs | asyncpg docs | https://magicstack.github.io/asyncpg/current/ | downloaded |
| candidate_repo | mysqlclient repo | https://github.com/PyMySQL/mysqlclient | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
