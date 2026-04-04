# CLI tooling lane Best-In-Class Selection

Date: 2026-04-03
Lane: `cli`
Selected benchmark: `psql`

## Selection Summary

psql is still the best-in-class benchmark for serious database CLI workflows because it
combines scripting, introspection, copy/import/export, transaction control, formatting,
and battle-tested automation semantics in one tool.

## Candidate Pool

`psql`, `usql`, `mycli`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| psql | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| usql | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| mycli | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The CLI lane is operational and conformance-capable, but lane-local mapping still marks
TXN, META, TYPE, and RES as partial. Tooling parity has to be judged against operational CLIs, not just raw driver APIs.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | psql docs | https://www.postgresql.org/docs/current/app-psql.html | downloaded |
| selected_repo | PostgreSQL repo | https://github.com/postgres/postgres | downloaded |
| candidate_repo | usql repo | https://github.com/xo/usql | downloaded |
| candidate_docs | mycli project | https://www.mycli.net/ | downloaded |
| candidate_repo | mycli repo | https://github.com/dbcli/mycli | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
