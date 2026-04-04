# Node.js/TypeScript driver Best-In-Class Selection

Date: 2026-04-03
Lane: `node`
Selected benchmark: `node-postgres`

## Selection Summary

node-postgres is still the best direct Node benchmark because of its mature pooling,
prepared statements, cursor/stream support, and enormous ecosystem adoption.

## Candidate Pool

`node-postgres`, `mysql2`, `tedious`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| node-postgres | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| mysql2 | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| tedious | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The Node lane is already strong and should now be pushed toward node-postgres-class
polish and evidence. Competitive closure is mainly around performance proof, cancellation ergonomics, and
ecosystem guidance.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | node-postgres docs | https://node-postgres.com/ | downloaded |
| selected_repo | node-postgres repo | https://github.com/brianc/node-postgres | downloaded |
| candidate_docs | mysql2 docs | https://sidorares.github.io/node-mysql2/docs | downloaded |
| candidate_repo | tedious repo | https://github.com/tediousjs/tedious | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
