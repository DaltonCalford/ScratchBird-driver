# PHP Driver Migration Guide

Status: Draft
Priority: P0

## Scope

Guidance for migrating existing applications to the ScratchBird PHP driver.

## Key Differences

- SBWP native protocol, not PostgreSQL/MySQL wire protocol.
- Binary-only parameters; text-only drivers must be upgraded.
- SQLSTATE mapping may differ from existing driver defaults.

## Migration Checklist

- Update DSN/connection config keys.
- Validate binary-only parameter binding.
- Verify SQLSTATE mapping behavior.
- Re-run integration tests against ScratchBird.
