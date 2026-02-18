# ScratchBird Pascal/Delphi Driver

ScratchBird native wire protocol client and adapters for Delphi/FreePascal.

## Documentation

- Getting started: `docs/getting-started/pascal.md`
- API reference: `docs/api-reference/pascal.md`

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.
The driver now defaults to first-party native transport/TLS units in
`tracks/alpha/drivers/pascal/src` and has no mandatory third-party runtime
dependency.

Native TLS status for `0.1.0`: API/state-machine/record framing plus first-party
crypto (`SHA-256`, `HMAC-SHA256`, `HKDF`) and certificate policy checks
(SAN/CN hostname matching, validity, usage, revocation policy hook) are
implemented in-driver. Wire handshake exchange, certificate parsing, and record
AEAD encryption/decryption are still in progress, so runtime connect attempts
still fail with explicit `not implemented` errors.

Temporary compatibility path: define `SCRATCHBIRD_USE_INDY` and add vendored Indy
paths (`third_party/indy/Lib/Core`, `Lib/Protocols`, `Lib/System`, `Lib/Security`)
if you need legacy transport during migration.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build coverage (`fpc` compile). |
| Windows | Supported | CI build coverage (`fpc` compile). |
| macOS | Untested | Not currently covered in CI. |

## Usage (core client)

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
