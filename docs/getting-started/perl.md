# Perl DBI Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `planned_beta1`
- Best-in-class benchmark: `DBD::Pg`
- Authoritative lane spec: `docs/specifications/drivers/PERL_DBI_DRIVER_SPECIFICATION.md`
- Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/perl/BEST_IN_CLASS_RESEARCH.md`
- Lane gap report: `docs/audit/BETA1_EXPANSION_PERL_GAP_REPORT.md`
- Remaining gap summary: The lane is fully specified for implementation, but the driver package, CPAN artifacts, and live evidence do not exist yet.
<!-- lane-status:end -->

## Planned Build / Install Root

- Planned track root: `tracks/beta/drivers/perl`

## Planned Package Identity

- CPAN-style ScratchBird DBI/DBD package
- release evidence path: `release/readiness/perl/<version>/`

## First Implementation Focus

- implement DBI connect and statement handles
- implement bind/execute/fetch and transaction controls
- implement metadata and diagnostics
- implement CPAN-ready packaging

## Later Smoke Scenarios

- connect and issue a simple query
- prepare and execute with bind placeholders
- fetch rows and inspect metadata
- commit and rollback a transaction

