[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Pascal/Delphi Driver Guide

**Status:** Initial Early Beta (`0.1.0`) (SBWP v1.1 baseline)
**Last Updated:** 2026-02-18

---

## Overview

ScratchBird native client and adapters for Delphi/FreePascal.

## Install

```bash
cd tracks/p3/drivers/pascal
# Add src/ to your unit search path, then compile with FPC or Delphi.
```

FreePascal builds require Indy (`IdTCPClient`, `IdSSL`, `IdSSLOpenSSL` units).
Indy is vendored at `tracks/p3/drivers/pascal/third_party/indy`. Add
`Lib/Core`, `Lib/Protocols`, `Lib/System`, and `Lib/Security` to your `-Fu`
search paths, or build `Lib/indylaz.lpk` and add the package.
TLS 1.3 is required; Indy 10 does not provide TLS 1.3 by default, so the client
will refuse to connect unless you supply a TLS 1.3-capable Indy build and compile
with `SCRATCHBIRD_TLS13` defined.

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

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/pascal.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/pascal.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/p3/drivers/pascal/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_PASCAL_URL`.
