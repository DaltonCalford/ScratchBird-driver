# Superset adapter Best-In-Class Selection

Date: 2026-04-03
Lane: `superset`
Selected benchmark: `Superset PostgreSQL engine spec`

## Selection Summary

The PostgreSQL engine spec is the strongest benchmark because it is the richest broadly
used SQL backend in Superset and exercises reflection, SQL Lab, time grains, and
metadata behavior deeply.

## Candidate Pool

`Superset PostgreSQL engine spec`, `Superset MySQL engine spec`, `Superset Trino engine spec`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Superset PostgreSQL engine spec | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| Superset MySQL engine spec | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| Superset Trino engine spec | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The Superset package exists, but it is still closer to a good custom backend than a
benchmarked first-class engine spec. Competitive closure has to cover SQL Lab, engine-spec feature flags, dataset discovery,
and packaging.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | Superset DB engine specs | https://github.com/apache/superset/tree/master/superset/db_engine_specs | downloaded |
| selected_repo | Superset repo | https://github.com/apache/superset | downloaded |
| candidate_repo | Superset repo | https://github.com/apache/superset | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
