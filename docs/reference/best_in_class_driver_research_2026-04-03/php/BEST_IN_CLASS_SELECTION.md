# PHP driver Best-In-Class Selection

Date: 2026-04-03
Lane: `php`
Selected benchmark: `PDO_PGSQL`

## Selection Summary

PDO_PGSQL is the best benchmark because it sets the expectation for mainstream PHP
relational ergonomics, parameter binding, and framework compatibility.

## Candidate Pool

`PDO_PGSQL`, `ext-pgsql`, `amphp/postgres`

## Scored Rubric

| Candidate | API completeness and standards conformance | Transaction and error semantics correctness | Metadata and tooling compatibility depth | Type fidelity and advanced type support | Performance and batching/streaming behavior | Security/auth/TLS posture | Pooling/resilience/recovery behavior | Documentation/release quality | Ecosystem adoption and maintenance health | Total |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| PDO_PGSQL | 19 | 14 | 9 | 9 | 14 | 9 | 9 | 5 | 5 | 93 |
| ext-pgsql | 16 | 13 | 8 | 8 | 12 | 8 | 8 | 4 | 4 | 81 |
| amphp/postgres | 14 | 11 | 7 | 7 | 10 | 7 | 7 | 4 | 4 | 71 |

## Current ScratchBird Truth

The PHP lane is functionally strong and should be driven toward PDO-grade polish and
ecosystem clarity. The competitive target is ergonomics and release quality, not just baseline query
support.

## Selected Benchmark Sources

| Type | Label | URL | Status |
| --- | --- | --- | --- |
| selected_docs | PDO_PGSQL source | https://github.com/php/php-src/tree/master/ext/pdo_pgsql | downloaded |
| selected_repo | PHP source repo | https://github.com/php/php-src | downloaded |
| candidate_docs | ext-pgsql source | https://github.com/php/php-src/tree/master/ext/pgsql | downloaded |
| candidate_repo | amphp/postgres repo | https://github.com/amphp/postgres | downloaded |

## Why The Selected Benchmark Won

- It is the strongest practical benchmark for this lane’s primary workload shape.
- It exposes enough public behavior and source structure to act as a real implementation anchor.
- It raises the bar on packaging, documentation, and operational expectations instead of only API surface.
