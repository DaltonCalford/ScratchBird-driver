# Beta 1 Expansion Perl DBI Gap Report

Status: Current
Lane: `perl`
Benchmark: `DBD::Pg`
Research packet: `docs/reference/beta1_expansion_server_independent_2026-04-03/perl/BEST_IN_CLASS_RESEARCH.md`

## Current ScratchBird Truth

- the lane is active Beta 1 authority
- the top-level spec and public docs exist
- implementation is not started
- no live proof exists yet

## Functional Gaps

- no DBI/DBD handle implementation exists yet
- no placeholder, transaction, or statement attribute behavior exists yet
- no Perl-native metadata and diagnostic behavior exists yet

## Metadata And Type Gaps

- no DBI-compatible type and null-handling matrix exists yet
- no SQLSTATE/diagnostic mapping into DBI conventions exists yet
- no statement-handle metadata contract exists yet

## Packaging And Tooling Gaps

- no CPAN-ready packaging or build guidance exists yet
- no Perl smoke tests or CPAN install workflow exists yet
- no release evidence specialized for CPAN consumers exists yet

## Live-Proof-Only Gaps

- DBI contract semantics need proof against a real ScratchBird server
- metadata and diagnostic fidelity need live verification
- install/build proof must be run in supported Perl environments

## Offline Closure Target

Offline closure is achieved when the Perl lane docs fully define the DBI/DBD
contract, packaging expectations, and later proof steps.
