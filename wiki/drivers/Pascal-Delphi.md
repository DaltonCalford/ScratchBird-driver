[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# Pascal/Delphi Driver Guide

**Status:** Alpha track (SBWP v1.1 baseline)
**Last Updated:** 2026-02-04

---

## Overview

ScratchBird native client and adapters for Delphi/FreePascal.

## Install

```bash
# Build from source in pascal/
```

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
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/tracks/alpha/drivers/pascal/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_PASCAL_URL`.

