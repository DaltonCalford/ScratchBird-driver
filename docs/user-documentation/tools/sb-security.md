# sb_security

User/role management CLI for ScratchBird.

## Status

Baseline implementation available; feature coverage evolves with server releases.

## Synopsis

```
sb_security [OPTIONS] <command>
```

## Purpose

- Create/drop users and roles
- Grant/revoke permissions
- Inspect security metadata

## Connection Options

```
sb_security -H host -p 3092 -U admin -d scratchbird <command>
```

## Notes

- Uses SBWP v1.1 and TLS 1.3.
- See the ScratchBird engine docs for supported commands and privileges.
