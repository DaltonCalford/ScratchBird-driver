# sb_admin

Administrative command-line tool for ScratchBird servers.

## Status

Baseline implementation available; feature coverage evolves with server releases.

## Synopsis

```
sb_admin [OPTIONS] <command> [command options]
```

## Purpose

- Server health checks
- Configuration inspection and updates
- Job and monitoring operations (when supported by server)

## Connection Options

Use standard SBWP v1.1 connection flags:

```
sb_admin -H host -p 3092 -U admin -d scratchbird <command>
```

## Notes

- Uses SBWP v1.1 and TLS 1.3.
- See the ScratchBird engine docs for server-side command availability.
