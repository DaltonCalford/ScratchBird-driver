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

Use standard SBWP v1.1 connection flags and mode selectors:

```
sb_admin -H host -p 3092 -U admin -d scratchbird <command>
sb_admin --mode=managed --manager-auth-token=... <database> <command>
sb_admin --mode=local-ipc --ipc-method=unix --ipc-path=build/ipc/scratchbird-main.sock <database> <command>
```

Supported connection modes:

- `--mode=inet` (listener TCP)
- `--mode=managed` (manager proxy front-door)
- `--mode=local-ipc` (`--ipc-method` / `--ipc-path`)
- `--mode=embedded` (currently routed through local IPC in beta C++ client runtime)

## Notes

- Uses SBWP v1.1 and TLS 1.3.
- See the ScratchBird engine docs for server-side command availability.
