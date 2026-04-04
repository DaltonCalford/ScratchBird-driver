# Ruby Driver Implementation Plan

Status: Current
Priority: P1

## Phase 1 - Offline-Complete Work

- freeze benchmark target `ruby-pg`
- push current lane truth into authoritative lane docs
- enumerate remaining implementation deltas with no hidden assumptions
- wire shared release-evidence requirements into this lane
- define later server-verification commands and artifact paths

## Phase 2 - Remaining Code Or Live-Proof Work

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is live proof collection and packaging evidence

## Later Build / Verification Commands

Build/bootstrap commands:

- `cd tracks/p3/drivers/ruby`
- `gem build scratchbird.gemspec`

Verification commands:

- `ruby -Ilib:test test/*.rb`

## Output Contracts

- release evidence under `release/readiness/ruby/<version>/`
- later verification packet in `docs/development/server-verification/ruby.md`
