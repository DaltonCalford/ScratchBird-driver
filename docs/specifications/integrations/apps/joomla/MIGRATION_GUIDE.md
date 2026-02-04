# joomla Integration Migration Guide

Status: Draft
Priority: P2
Category: Application

## Scope

Guidance for migrating existing joomla configurations to ScratchBird.

## Key Differences

- SBWP native protocol, not PostgreSQL/MySQL wire protocol.
- Binary-only parameters; text-only drivers must be upgraded.
- SQLSTATE mapping may differ from existing driver defaults.

## Migration Checklist

- Update connection configuration.
- Validate metadata queries.
- Verify SQLSTATE mapping.
