# Hibernate Dialect Compatibility Specification

**Document Version:** 1.0
**Created:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support Hibernate Dialect with ScratchBird

## Executive Summary

- **Selected Benchmark:** `Hibernate PostgreSQLDialect`
- **Current Lane State:** `partial_contract_only`
- **Track Root:** `tracks/alpha/integrations/scratchbird-hibernate-dialect`

## Current Truth

- current lane is still contract-first rather than fully validated runtime integration
- schema-management, migration, and ORM lifecycle proof remain server-blocked

## Mandatory Competitive Closure

- freeze dialect registration, ORM lifecycle, DDL compilation, and migration acceptance gates
- require live ORM bootstrap and schema-management evidence

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/hibernate.md`
- Getting started: `docs/getting-started/hibernate.md`
- Later verification packet: `docs/development/server-verification/hibernate.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

## Required Release Evidence

- contract tests
- conformance report
- compatibility matrix
- performance numbers
- known-gap list
- packaging and release cadence statement
