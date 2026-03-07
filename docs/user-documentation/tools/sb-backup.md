# sb_backup

Backup and restore CLI for ScratchBird databases.

## Status

Baseline implementation available; advanced formats depend on server support.

## Synopsis

```
sb_backup [OPTIONS] <command>
```

## Purpose

- Create logical or binary backups (server-dependent)
- Restore backups to a target database
- Verify backup integrity (when supported)

## Connection Options

```
sb_backup -H host -p 3092 -U admin -d scratchbird <command>
```

## Notes

- Connection behavior follows the current ScratchBird CLI lane build. Prefer
  TLS-enabled modes in production deployments.
- See the ScratchBird engine docs for backup formats and feature coverage.
