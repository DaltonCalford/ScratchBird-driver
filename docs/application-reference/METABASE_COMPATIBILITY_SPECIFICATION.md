# Metabase Plugin Compatibility Specification

**Document Version:** 1.0
**Created:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support Metabase Plugin with ScratchBird

## Executive Summary

- **Selected Benchmark:** `Metabase PostgreSQL driver`
- **Current Lane State:** `partial_adapter`
- **Track Root:** `tracks/alpha/integrations/scratchbird-metabase-driver`

## Current Truth

- schema sync, field fingerprinting, and native-query validation remain server-blocked
- packaged plugin/runtime validation remains open

## Mandatory Competitive Closure

- freeze schema sync, fingerprinting, native query, and feature-flag behavior against the PostgreSQL driver
- require packaging and sync-performance evidence

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/metabase.md`
- Getting started: `docs/getting-started/metabase.md`
- Later verification packet: `docs/development/server-verification/metabase.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

## Required Release Evidence

- contract tests
- conformance report
- compatibility matrix
- performance numbers
- known-gap list
- packaging and release cadence statement
