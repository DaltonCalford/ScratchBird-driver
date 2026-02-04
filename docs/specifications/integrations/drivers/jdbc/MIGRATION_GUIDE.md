# JDBC 4.2 Integration Migration Guide

Status: Draft
Priority: P0
Category: Standard Protocol

## Scope

Guidance for migrating existing JDBC 4.2 configurations to ScratchBird.

## Key Differences

- SBWP native protocol, not PostgreSQL/MySQL wire protocol.
- Binary-only parameters; text-only drivers must be upgraded.
- SQLSTATE mapping may differ from existing driver defaults.

## Migration Checklist

- Update connection configuration.
- Validate metadata queries.
- Verify SQLSTATE mapping.
