# .NET Driver

<!-- lane-status:start -->
## Current Status

- Lane kind: `driver`
- Current state: `baseline_complete`
- Best-in-class benchmark: `Npgsql`
- Authoritative lane spec: `docs/specifications/drivers/language/dotnet-csharp/SPECIFICATION.md`
- Shared release evidence templates: `docs/development/release-evidence/README.md`
- Later verification packet: `docs/development/server-verification/dotnet.md`
- Remaining gap summary: No lane-local JDBC/.NET-class baseline gaps remain. Remaining work is live proof collection and release evidence staging.
<!-- lane-status:end -->

## Install

Build the provider from the repo:

```bash
dotnet build tracks/p3/drivers/dotnet/src/ScratchBird.Data/ScratchBird.Data.csproj
```

For application development, add a project or package reference to
`ScratchBird.Data`.

## Quick Start

```csharp
using ScratchBird.Data;

using var conn = new ScratchBirdConnection(
    "Host=localhost;Port=3092;Database=mydb;Username=user;Password=pass;SSLMode=require");
conn.Open();

using var cmd = conn.CreateCommand();
cmd.CommandText = "SELECT 1";
var result = cmd.ExecuteScalar();
```

## Connection Strings

Direct/native:

```
Host=localhost;Port=3092;Database=mydb;Username=user;Password=pass;SSLMode=require
```

Manager-proxy:

```
Host=localhost;Port=3090;Database=mydb;Username=user;Password=pass;FrontDoorMode=manager_proxy;ManagerAuthToken=token
```

Current lane behavior:

- TLS is the default posture.
- `SSLMode=disable` is only allowed when `AllowInsecure=true` (or
  `allow_insecure_disable=true` in DSN form).
- Pooling, `FetchSize`, manager-proxy keys, and auth-plugin startup keys are
  supported.
- `binary_transfer=false` and `compression=zstd` are not currently supported by
  the .NET lane.

## Enterprise Extensions

The .NET lane also exposes diagnostics, telemetry, notifications, and query
pipeline surfaces. See [API reference](../api-reference/dotnet.md).

## Tests

Integration tests are gated by:

- `SCRATCHBIRD_DOTNET_URL`
