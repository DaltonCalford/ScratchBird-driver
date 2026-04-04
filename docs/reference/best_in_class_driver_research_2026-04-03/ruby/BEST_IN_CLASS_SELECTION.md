# Ruby driver Best-In-Class Selection

Date: 2026-04-03
Lane: `ruby`
Selected benchmark: `ruby-pg`

## Selection Summary

ruby-pg is the strongest benchmark because it is the canonical direct relational client
in the Ruby ecosystem, with mature prepared statement, copy, and transaction behavior.

## Candidate Pool

`ruby-pg`, `mysql2`, `tiny_tds`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| ruby-pg | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| mysql2 | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| tiny_tds | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The Ruby lane is functionally strong; closure is about polish, release proof, and Rails-
facing usability. The benchmark should stay on the direct `pg` gem rather than generic wrappers.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_repo | ruby-pg repo | https://github.com/ged/ruby-pg | downloaded |
| candidate_repo | mysql2 repo | https://github.com/brianmario/mysql2 | downloaded |
| candidate_repo | tiny_tds repo | https://github.com/rails-sqlserver/tiny_tds | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
