[Back to Drivers](Driver-Comparison.md) | [Back to Home](../Home.md)

# .NET Driver Guide

**Status:** Implemented (SBWP v1.1 baseline)
**Last Updated:** 2026-02-02

---

## Overview

ScratchBird ADO.NET provider using the native protocol.

## Install

```bash
dotnet build dotnet/src/ScratchBird.Data/ScratchBird.Data.csproj
```

## Quick Start

```csharp
using ScratchBird.Data;

var conn = new ScratchBirdConnection("scratchbird://user:pass@localhost:3092/mydb");
conn.Open();
using var cmd = conn.CreateCommand();
cmd.CommandText = "SELECT 1";
var result = cmd.ExecuteScalar();
conn.Close();
```

## Documentation

- [Getting started](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/getting-started/dotnet.md)
- [API reference](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/api-reference/dotnet.md)
- [Driver README](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/dotnet/README.md)

## Configuration

See [DSN and config standard](https://github.com/DaltonCalford/ScratchBird-driver/blob/main/docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md).

## Testing

Integration tests use `SCRATCHBIRD_DOTNET_URL`.

