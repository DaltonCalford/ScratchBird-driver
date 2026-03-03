# ScratchBird .NET Driver

ScratchBird ADO.NET provider using the native wire protocol.

## Documentation

- Getting started: `docs/getting-started/dotnet.md`
- API reference: `docs/api-reference/dotnet.md`
- Baseline requirement mapping: `BASELINE_REQUIREMENT_MAPPING.md`

## Build/Test (Windows/Linux)

See `docs/BUILD_MATRIX.md`.

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build/test coverage. |
| Windows | Supported | CI build/test coverage. |
| macOS | Untested | Not currently covered in CI. |

## Build

```bash
dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj
```

## Tests

```bash
dotnet test
```

Integration env:

- `SCRATCHBIRD_DOTNET_URL`
