# Driver Server-Independent Completion Model

Status: Current
Last Updated: 2026-04-03

## Purpose

Define the shared model for finishing all driver-repo work that does not
require a running ScratchBird test server.

## Core Rule

Server-independent completion means:

- authoritative implementation specs are current
- benchmark and gap truth are current
- release-evidence templates are frozen
- later verification packets are explicit
- integration-tree authority is explicit

It does not mean:

- live conformance has been re-run
- performance claims are measured for the current build
- compatibility claims are fully proven against a running server

## Required Companion Documents

- `DRIVER_LANE_AUTHORITY_INDEX.md`
- `DRIVER_RELEASE_READINESS_EVIDENCE_CONTRACT.md`
- `DRIVER_SERVER_VERIFICATION_PACKET_CONTRACT.md`
- `DRIVER_INTEGRATION_AUTHORITY_AND_SUPERSESSION_MAP.md`
- `docs/development/release-evidence/README.md`
- `docs/development/server-verification/README.md`
