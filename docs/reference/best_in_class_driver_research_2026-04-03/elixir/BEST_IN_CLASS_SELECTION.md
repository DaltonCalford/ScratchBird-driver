# Elixir/Ecto driver Best-In-Class Selection

Date: 2026-04-03
Lane: `elixir`
Selected benchmark: `Postgrex`

## Selection Summary

Postgrex remains the strongest direct Elixir benchmark because of its mature protocol
handling, Ecto integration, telemetry surface, and proven transaction/query semantics.

## Candidate Pool

`Postgrex`, `MyXQL`, `Tds`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Postgrex | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| MyXQL | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| Tds | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The lane is close, but EXEC stream/paging proof and in-place reconnect behavior still
lag the strongest Elixir drivers. The benchmark has to include both direct driver and Ecto adapter behavior.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | Postgrex docs | https://hexdocs.pm/postgrex/readme.html | downloaded |
| selected_repo | Postgrex repo | https://github.com/elixir-ecto/postgrex | downloaded |
| candidate_docs | MyXQL docs | https://hexdocs.pm/myxql/readme.html | downloaded |
| candidate_docs | Tds docs | https://hexdocs.pm/tds/readme.html | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
