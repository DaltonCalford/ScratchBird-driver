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
sb_security -H host -p 3092 -U admin --sslmode=require -d scratchbird <command>
sb_security --mode=managed --manager-auth-token=... --front-door-mode=manager_proxy <command> <database>
sb_security --mode=local-ipc --ipc-method=unix --ipc-path=build/ipc/scratchbird-main.sock <command> <database>
```

Supported connection modes:

- `--mode=inet` (listener TCP)
- `--mode=managed` (manager proxy front-door)
- `--mode=local-ipc` (`--ipc-method` / `--ipc-path`)
- `--mode=embedded` (currently routed through local IPC in beta C++ client runtime)

## Notes

- The current CLI lane accepts the standard `sslmode` values
  (`disable|allow|prefer|require|verify-ca|verify-full`) and manager-proxy
  routing controls such as `--front-door-mode` and `--manager-auth-token`.
- See the ScratchBird engine docs for supported commands and privileges.
