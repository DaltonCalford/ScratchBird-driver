# Perl DBI Driver Specification

**Document Version:** 1.1
**Created:** 2026-04-03
**Last Updated:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support the ScratchBird Perl DBI driver at Beta 1 quality

## Executive Summary

- **Selected Benchmark:** `DBD::Pg`
- **Current Lane State:** `planned_beta1`
- **Planned Track Root:** `tracks/beta/drivers/perl`
- **Research Packet:** `docs/reference/beta1_expansion_server_independent_2026-04-03/perl/BEST_IN_CLASS_RESEARCH.md`
- **Lane Gap Report:** `docs/audit/BETA1_EXPANSION_PERL_GAP_REPORT.md`

## Current Truth

- This lane is promoted to active Beta 1 authority in advance of implementation.
- The lane must satisfy the Perl DBI contract rather than acting like a generic
  SQL wrapper.
- The remaining work is intentionally reduced to `implementation_pending` plus
  `server_blocked` release proof.

## Mandatory Competitive Closure

- match or exceed `DBD::Pg` for DBI contract behavior where applicable
- provide deterministic statement-handle, placeholder, transaction, and
  diagnostic behavior
- preserve metadata/error fidelity comparable to the strongest DBI PostgreSQL
  path

## Required Capability Families

- DBI `connect`, handle attributes, and statement lifecycle
- placeholders, execute-array style batching, and transaction control
- metadata and diagnostics expected by DBI consumers
- type/null behavior and error mapping suitable for Perl DB apps
- CPAN-grade packaging and install behavior

## Required Packaging And Integration Surface

- CPAN-ready package identity and distribution layout
- explicit Perl/runtime/build dependency matrix
- release-evidence staging at `release/readiness/perl/<version>/`
- examples for DBI connect/prepare/execute/fetch patterns

## Required Build And Verification Entry Points

Implementation must provide these deterministic commands at the lane root:

1. bootstrap/build: `perl Makefile.PL && make`
2. contract and conformance: `make test`
3. performance: `perl bench/run.pl`

## Implementation Sequence

1. DBI connect and statement-handle bootstrap
2. prepare/bind/execute/fetch behavior
3. transaction and metadata/diagnostics coverage
4. CPAN packaging and release-evidence automation

## Remaining Work Classification

### Implementation Pending

- implement the DBI/DBD driver package
- implement metadata, diagnostics, and type/null handling
- implement CPAN-ready packaging and examples

### Server Blocked

- validate DBI contract behavior against a live ScratchBird server
- publish compatibility and performance evidence
- prove install/build behavior on supported Perl environments

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/perl.md`
- Getting started: `docs/getting-started/perl.md`
- Later verification packet: `docs/development/server-verification/perl.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

