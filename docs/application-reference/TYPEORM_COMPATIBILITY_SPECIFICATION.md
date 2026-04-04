# TypeORM Adapter Compatibility Specification

**Document Version:** 1.0
**Created:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support TypeORM Adapter with ScratchBird

## Executive Summary

- **Selected Benchmark:** `TypeORM PostgreSQL driver`
- **Current Lane State:** `partial_contract_only`
- **Track Root:** `tracks/alpha/integrations/scratchbird-typeorm-adapter`

## Current Truth

- current lane is still contract-first rather than fully validated runtime integration
- migrations, relations, and query-builder behavior remain server-blocked

## Mandatory Competitive Closure

- freeze datasource, migrations, relations, and query-builder acceptance gates against the PostgreSQL driver
- require relation and schema-management evidence

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/typeorm.md`
- Getting started: `docs/getting-started/typeorm.md`
- Later verification packet: `docs/development/server-verification/typeorm.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

## Required Release Evidence

- contract tests
- conformance report
- compatibility matrix
- performance numbers
- known-gap list
- packaging and release cadence statement
