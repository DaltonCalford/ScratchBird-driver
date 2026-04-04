# Perl DBI Best-In-Class Research

Status: Current
Lane: `perl`
Benchmark: `DBD::Pg`

## Why This Benchmark

DBD::Pg is the strongest open benchmark for Perl database connectivity built on
the DBI contract. It sets the expectation level for:

- DBI handle lifecycle and attribute behavior
- prepared statements, placeholders, and transactions
- metadata and error reporting via DBI conventions
- packaging and CPAN distribution quality

## Official Sources

- DBD::Pg MetaCPAN docs:
  `https://metacpan.org/dist/DBD-Pg`
- DBI API docs:
  `https://metacpan.org/pod/DBI`
- Implementation anchor:
  `https://github.com/bucardo/dbdpg`

## Capability Families That Become Non-Optional

- DBI `connect`, handle attributes, and statement lifecycle
- placeholders, execute-array behavior, and transaction controls
- metadata, diagnostics, and error mapping aligned to DBI expectations
- packaging suitable for CPAN and native build distribution

## ScratchBird Implementation Implications

- the lane must implement DBI-native behavior rather than a minimal wrapper
- metadata and diagnostic fidelity matter because Perl users depend heavily on
  DBI conventions
- packaging strategy needs to account for CPAN install expectations and native
  build prerequisites

## Later Server Validation Focus

- DBI contract tests for connect/prepare/execute/fetch
- metadata and diagnostic behavior
- transaction/savepoint correctness
- CPAN-style packaging and install proof
