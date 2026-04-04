# Perl DBI Driver Server Verification Packet

Status: server_blocked

## Scope

- lane: `perl`
- benchmark: `DBD::Pg`
- current state: `planned_beta1`
- planned track root: `tracks/beta/drivers/perl`
- research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/perl/BEST_IN_CLASS_RESEARCH.md`
- gap report: `docs/audit/BETA1_EXPANSION_PERL_GAP_REPORT.md`

## Required Environment

- `SCRATCHBIRD_TEST_DSN`
- supported Perl runtime and build toolchain
- any CPAN test prerequisites required by the lane

## Build / Bootstrap Commands

1. `cd tracks/beta/drivers/perl`
2. `perl Makefile.PL && make`

## Verification Commands

1. contract/conformance: `make test`
2. performance: `perl bench/run.pl`

## Expected Artifacts

- `release/readiness/perl/<version>/CONTRACT_TEST_RESULTS.json`
- `release/readiness/perl/<version>/CONFORMANCE_REPORT.md`
- `release/readiness/perl/<version>/COMPATIBILITY_MATRIX.md`
- `release/readiness/perl/<version>/PERFORMANCE_NUMBERS.md`
- `release/readiness/perl/<version>/KNOWN_GAPS.md`
- `release/readiness/perl/<version>/PACKAGING_AND_RELEASE_CADENCE.md`
- `release/readiness/perl/<version>/SUMMARY.json`

## Pass / Fail Rule

Pass only when:

- every capability family from `docs/specifications/drivers/PERL_DBI_DRIVER_SPECIFICATION.md` is implemented and proven
- DBI semantics and diagnostics are proven rather than assumed
- all release evidence is staged under `release/readiness/perl/<version>/`

