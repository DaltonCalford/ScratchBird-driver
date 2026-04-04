# DBeaver Extension Compatibility Specification

**Document Version:** 1.0
**Created:** 2026-04-03
**Status:** Current
**Scope:** Requirements to support DBeaver Extension with ScratchBird

## Executive Summary

- **Selected Benchmark:** `DBeaver PostgreSQL extension`
- **Current Lane State:** `partial_plugin`
- **Track Root:** `tracks/alpha/integrations/scratchbird-dbeaver-driver`

## Current Truth

- UI plugin packaging and update-site installation proof remain open
- schema navigator, editor payload, and query-preview behavior need later live validation

## Mandatory Competitive Closure

- freeze plugin packaging, update-site install, schema-tree behavior, and editor metadata expectations
- require DBeaver-side UI and navigator goldens in release evidence

## Authoritative Supporting Docs

- API/reference: `docs/api-reference/dbeaver.md`
- Getting started: `docs/getting-started/dbeaver.md`
- Later verification packet: `docs/development/server-verification/dbeaver.md`
- Release evidence templates: `docs/development/release-evidence/README.md`

## Required Release Evidence

- contract tests
- conformance report
- compatibility matrix
- performance numbers
- known-gap list
- packaging and release cadence statement
