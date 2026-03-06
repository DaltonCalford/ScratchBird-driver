# .NET Driver

## Install

From the repo:

```bash
dotnet build tracks/alpha/drivers/dotnet/src/ScratchBird.Data/ScratchBird.Data.csproj
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

Pooling tuning options:

- `Pooling=true|false`
- `MinPoolSize`, `MaxPoolSize`, `ConnectionLifetime`
- `PoolingAcquireTimeout` (seconds) or `PoolAcquireTimeoutMs` (milliseconds)

## TLS

TLS 1.3 is required. `sslmode=disable` is rejected.

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_DOTNET_URL`
