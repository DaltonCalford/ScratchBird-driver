# C/C++ Driver Implementation Plan

Status: Current
Priority: P0

## Phase 1 - Offline-Complete Work

- freeze benchmark target `libpqxx`
- push current lane truth into authoritative lane docs
- enumerate remaining implementation deltas with no hidden assumptions
- wire shared release-evidence requirements into this lane
- define later server-verification commands and artifact paths

## Phase 2 - Remaining Code Or Live-Proof Work

- no lane-local JDBC/.NET-class baseline gaps remain
- remaining work is server-backed proof collection and competitive release evidence

## Later Build / Verification Commands

Build/bootstrap commands:

- `cmake -S tracks/p3/drivers/cpp -B build-cpp -DCMAKE_BUILD_TYPE=Release`
- `cmake --build build-cpp --config Release`

Verification commands:

- `ctest --test-dir build-cpp --output-on-failure`
- `scratchbird_client_tests`

## Output Contracts

- release evidence under `release/readiness/cpp/<version>/`
- later verification packet in `docs/development/server-verification/cpp.md`
