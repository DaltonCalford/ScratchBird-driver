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
sb_admin -H host -p 3092 -U admin --sslmode=require -d scratchbird <command>
sb_admin --mode=managed --manager-auth-token=... --front-door-mode=manager_proxy <command>
sb_admin --mode=inet --auth-method-id=scratchbird.auth.scram_sha_256 --auth-method-payload=opaque-token <command>
sb_admin --mode=local-ipc --ipc-method=unix --ipc-path=build/ipc/scratchbird-main.sock <database> <command>
```

Supported connection modes:

- `--mode=inet` (listener TCP)
- `--mode=managed` (manager proxy front-door)
- `--mode=local-ipc` (`--ipc-method` / `--ipc-path`)
- `--mode=embedded` (currently routed through local IPC in beta C++ client runtime)

## Notes

- The current CLI lane accepts the same broad `sslmode` values used by the
  JDBC-parity drivers (`disable|allow|prefer|require|verify-ca|verify-full`).
- Auth-plugin-aware admin flows can use `--client-flags`,
  `--auth-method-id`, `--auth-method-payload`,
  `--auth-required-methods`, `--auth-forbidden-methods`,
  `--auth-require-channel-binding`, `--workload-identity-token`, and
  `--proxy-principal-assertion`.
- See the ScratchBird engine docs for server-side command availability.
