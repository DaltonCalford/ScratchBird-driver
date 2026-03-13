# Pascal/Delphi Driver

## Install

Add `tracks/p3/drivers/pascal/src` to your project search path.

Default builds use the first-party native transport/TLS units and require
OpenSSL runtime libraries (`libssl`/`libcrypto`).

## Quick Start

```pascal
uses
  ScratchBird.Client;

var
  Client: TScratchBirdClient;
begin
  Client := TScratchBirdClient.Create;
  try
    Client.Connect('scratchbird://user:pass@localhost:3092/mydb');
    Client.ExecSQL('SELECT 1');
  finally
    Client.Free;
  end;
end;
```

## Adapters

- FireDAC: `ScratchBird.FireDAC`
- IBX: `ScratchBird.IBX`
- Zeos: `ScratchBird.Zeos`
- SQLdb: `ScratchBird.SQLdb`

## Connection Strings

Direct/native:

```
scratchbird://user:password@host:3092/database?sslmode=prefer
```

Manager-proxy:

```
scratchbird://user:password@host:3090/database?front_door_mode=manager_proxy&manager_auth_token=token
```

Current lane behavior:

- Direct DSNs accept the standard `sslmode` values, including `disable`.
- Compatibility startup keys include `binary_transfer=false` and
  `compression=zstd|none|off`.
- Manager-proxy and auth-plugin startup keys are supported.

## Enterprise Extensions

The Pascal lane now includes diagnostics/telemetry JSON exports and notification
queue/listener helpers. See [API reference](../api-reference/pascal.md).

## Tests

Unit-level TLS coverage (crypto + policy):

- `fpc -Mdelphi -Fu./tracks/p3/drivers/pascal/src -FE./tracks/p3/drivers/pascal/tests ./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests.pas`
- `./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests`

Integration tests are gated by:

- `SCRATCHBIRD_PASCAL_URL`
