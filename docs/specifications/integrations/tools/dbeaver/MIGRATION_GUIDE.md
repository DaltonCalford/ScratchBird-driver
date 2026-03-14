# DBeaver Integration Migration Guide

Status: Updated 2026-03-13
Priority: P0
Category: Database Tool

## Scope

Move DBeaver support from ad-hoc local checkout edits to the tracked
`ScratchBird-driver` integration lane.

## Recommended Migration Path

1. Treat `tracks/alpha/integrations/scratchbird-dbeaver-driver/` as the source
   of truth.
2. Build the ScratchBird JDBC JAR from `tracks/p3/drivers/jdbc/`.
3. Build the p2 update site from the DBeaver integration lane.
4. Install the plugin into stock DBeaver or seed a clean DBeaver source
   checkout with `install-into-dbeaver.sh`.
5. If using local JDBC builds, attach the local JAR in DBeaver Driver Manager.

## Current Local-Checkout Caveat

The existing `~/CliWork/dbeaver` staging checkout already contains ScratchBird
plugin/test files and modified reactor/feature files. Normalize that checkout
before treating it as a clean verification target.

## Key Behavioral Notes

1. ScratchBird DBeaver support rides on JDBC, not a PostgreSQL/MySQL wire
   impersonation.
2. Recursive schema directories come from the DBeaver adapter tree model.
3. Optional JDBC parent-schema expansion exists, but the DBeaver adapter does
   not depend on it.
