# Driver Server Verification Packet Contract

Status: Current
Last Updated: 2026-04-03

## Purpose

Define the required contents of the per-lane verification packets stored in
`docs/development/server-verification/`.

## Required Contents Per Packet

- exact track root
- selected benchmark
- current lane state
- required environment variables
- exact build/bootstrap commands
- exact verification commands
- expected staged release-evidence artifacts
- explicit pass/fail rule

## Rule

A lane may be called `server_blocked only` only when its verification packet
already exists and no hidden runbook knowledge is required beyond that file.
