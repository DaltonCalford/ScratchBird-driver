# Superset Driver Compatibility Specification

**Document Version:** 1.0
**Created:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support Superset Driver with ScratchBird

## Executive Summary

- **Selected Benchmark:** `Superset PostgreSQL engine spec`
- **Current Lane State:** `partial_adapter`
- **Track Root:** `tracks/beta/integrations/scratchbird-superset-driver`

## Current Truth

- EngineSpec behavior, SQL Lab validation, and deployment packaging remain server-blocked
- runtime sync and benchmark evidence remain open

## Mandatory Competitive Closure

- freeze EngineSpec, SQL Lab, and deployment expectations against the PostgreSQL engine spec
- require metadata sync, dialect, and packaging evidence

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/superset.md`
- Getting started: `docs/getting-started/superset.md`
- Later verification packet: `docs/development/server-verification/superset.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

## Required Release Evidence

- contract tests
- conformance report
- compatibility matrix
- performance numbers
- known-gap list
- packaging and release cadence statement
