# SQLAlchemy Dialect Compatibility Specification

**Document Version:** 1.0
**Created:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support SQLAlchemy Dialect with ScratchBird

## Executive Summary

- **Selected Benchmark:** `SQLAlchemy PostgreSQL dialect`
- **Current Lane State:** `partial_adapter`
- **Track Root:** `tracks/alpha/integrations/scratchbird-sqlalchemy-dialect`

## Current Truth

- deep reflection, DDL compilation, and Alembic behavior remain server-blocked
- production-grade packaging and benchmark evidence remain open

## Mandatory Competitive Closure

- freeze reflection, ORM lifecycle, DDL compilation, and Alembic-facing requirements against the PostgreSQL dialect
- require migration and ORM lifecycle evidence

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/sqlalchemy.md`
- Getting started: `docs/getting-started/sqlalchemy.md`
- Later verification packet: `docs/development/server-verification/sqlalchemy.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

## Required Release Evidence

- contract tests
- conformance report
- compatibility matrix
- performance numbers
- known-gap list
- packaging and release cadence statement
