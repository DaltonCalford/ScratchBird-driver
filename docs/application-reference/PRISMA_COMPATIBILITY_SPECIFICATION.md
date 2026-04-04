# Prisma Adapter Compatibility Specification

**Document Version:** 1.0
**Created:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support Prisma Adapter with ScratchBird

## Executive Summary

- **Selected Benchmark:** `Prisma PostgreSQL connector`
- **Current Lane State:** `partial_contract_only`
- **Track Root:** `tracks/alpha/integrations/scratchbird-prisma-adapter`

## Current Truth

- current lane is still contract-first rather than fully validated runtime integration
- introspection, migrations, and runtime query behavior remain server-blocked

## Mandatory Competitive Closure

- freeze datasource, introspection, migration, and native-type acceptance gates
- require runtime and schema workflow validation against the Prisma PostgreSQL connector bar

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/prisma.md`
- Getting started: `docs/getting-started/prisma.md`
- Later verification packet: `docs/development/server-verification/prisma.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

## Required Release Evidence

- contract tests
- conformance report
- compatibility matrix
- performance numbers
- known-gap list
- packaging and release cadence statement
