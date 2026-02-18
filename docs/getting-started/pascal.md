# Pascal/Delphi Driver

## Install

Add the `tracks/alpha/drivers/pascal/src` directory to your project search path.

Default builds use first-party native transport/TLS units and do not require
outside libraries.

Native TLS status for `0.1.0`: API/state machine/record framing plus first-party
crypto (`SHA-256`, `HMAC-SHA256`, `HKDF`) and certificate policy checks are in
place. Wire handshake exchange, certificate parsing, and record AEAD encryption
are still in progress, so connection attempts still fail with an explicit
`not implemented` error.

If you need temporary legacy connectivity during migration, define
`SCRATCHBIRD_USE_INDY` and add vendored Indy unit paths:

- `tracks/alpha/drivers/pascal/third_party/indy/Lib/Core`
- `tracks/alpha/drivers/pascal/third_party/indy/Lib/Protocols`
- `tracks/alpha/drivers/pascal/third_party/indy/Lib/System`
- `tracks/alpha/drivers/pascal/third_party/indy/Lib/Security`

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

URI:

```
scratchbird://user:password@host:3092/database?sslmode=require
```

Key-value:

```
host=localhost port=3092 dbname=mydb user=myuser password=mypass
```

See [DSN and config standard](../specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## TLS

TLS 1.3 is required. `sslmode=disable` is rejected.

## Tests

Unit-level TLS coverage (crypto + policy):

- `fpc -Mdelphi -Fu./tracks/alpha/drivers/pascal/src -FE./tracks/alpha/drivers/pascal/tests ./tracks/alpha/drivers/pascal/tests/TlsCryptoAndPolicyTests.pas`
- `./tracks/alpha/drivers/pascal/tests/TlsCryptoAndPolicyTests`

Integration tests are gated by:

- `SCRATCHBIRD_PASCAL_URL`
