# Perl DBI Driver API / Integration Reference

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `DBD::Pg`
- Authoritative lane spec: `docs/specifications/drivers/PERL_DBI_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/perl/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_PERL_GAP_REPORT.md`
- Remaining gap summary: The lane is specification-deepened and implementation-ready, but the DBI/DBD package and all live proof remain outstanding.
<!-- lane-status:end -->

## Planned Package Surface

- Perl DBI/DBD package for ScratchBird
- CPAN-style distribution and install guidance
- release evidence root: `release/readiness/perl/<version>/`

## Mandatory API Surface

- DBI connect/disconnect
- prepare/bind/execute/fetch helpers
- statement and handle attributes
- transaction and metadata/diagnostic behavior

## Non-Optional Behaviors

- DBI-native error/diagnostic semantics
- deterministic type/null behavior
- metadata and handle behavior not weaker than the benchmark

## Later Proof

- server verification packet: `docs/development/server-verification/perl.md`
- release evidence root: `release/readiness/perl/<version>/`

