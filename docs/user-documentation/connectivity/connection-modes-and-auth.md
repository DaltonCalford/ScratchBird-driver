# Connection Modes and Auth

Shared connectivity and authentication behavior for the maintained
ScratchBird-driver lanes.

[Back to Connectivity Index](README.md) | [Back to Documentation Index](../README.md)

## Native Connection Modes

### Direct Native

Use the ScratchBird native listener directly.

- Default front door: `direct`
- Typical port: `3092`
- Used by the JDBC-parity language drivers as the primary baseline

Examples:

```text
jdbc:scratchbird://host:3092/database
```

```text
Driver={ScratchBird};Server=host;Port=3092;Database=db;UID=user;PWD=pass
```

### Managed Native

Use the manager-proxy front door when the deployment requires it.

- Front door: `manager_proxy`
- Typical manager port: `3090`
- Requires `manager_auth_token`

Examples:

```text
jdbc:scratchbird://host:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

```text
Driver={ScratchBird};Server=host;Port=3090;Database=db;UID=user;PWD=pass;FrontDoorMode=manager_proxy;ManagerAuthToken=token
```

### Local Runtime Modes

Some tools expose local runtime modes such as `embedded` or `local-ipc`.
Those are mainly runtime/tooling surfaces, not the primary portability contract
for every maintained language driver.

Important lane note:

- The C/C++ driver in this repository is intentionally IP-only.
- Driver-side embedded and IPC responsibilities stay with ScratchBird runtime
  and server layers.

## Shared TLS and Startup Options

Modern JDBC-parity lanes share these common connection settings:

- `sslmode=disable|allow|prefer|require|verify-ca|verify-full`
- `binary_transfer=true|false`
- `compression=off|none|zstd`
- schema/session options such as `currentSchema` / `schema`
- timeout, pooling, fetch-size, read-only, and autocommit settings

Production deployments should use TLS-enabled modes.

Partial lanes may enforce stricter transport rules. When that happens, the
driver-specific getting-started guide is the source for that lane restriction.

## Auth Handshake Model

Drivers do not assume a specific server plugin set. The connection handshake is
responsible for selecting an authentication method that both sides can use.

Current maintained lanes may send:

- `client_flags` or `connect_client_flags`
- `auth_method_id`
- `auth_method_payload`
- `auth_payload_json`
- `auth_payload_b64`
- `auth_provider_profile`
- `auth_required_methods`
- `auth_forbidden_methods`
- `auth_require_channel_binding`
- `workload_identity_token`
- `proxy_principal_assertion`

What these mean:

- `auth_method_id`: explicitly request a ScratchBird auth method when the caller
  wants one specific method.
- `auth_required_methods` / `auth_forbidden_methods`: constrain what the server
  may pick.
- `auth_require_channel_binding`: require channel binding during negotiation.
- `workload_identity_token` / `proxy_principal_assertion`: carry external
  identity evidence into startup.

Compatibility note:

- Legacy peers can still use password or SCRAM compatibility paths.
- Registry-capable peers can negotiate plugin-backed methods without the driver
  needing a hard-coded plugin inventory.

## CLI Mode Mapping

The CLI tools normalize connection mode like this:

- `--mode=inet`: native direct network connection
- `--mode=managed`: native network connection plus
  `front_door_mode=manager_proxy`
- `--mode=local-ipc`: local runtime bridge / IPC transport
- `--mode=embedded`: local embedded/runtime mode when supported by the tool

The most complete examples are in:

- [CLI tool docs](../tools/README.md)
- [JDBC connectivity](jdbc.md)
- [ODBC connectivity](odbc.md)

## See Also

- [Getting Started index](../../getting-started/README.md)
- [API Reference index](../../api-reference/README.md)
- [JDBC connectivity](jdbc.md)
- [ODBC connectivity](odbc.md)
