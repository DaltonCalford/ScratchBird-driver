# ScratchBird .NET Driver

ScratchBird ADO.NET provider using the native wire protocol.

## Documentation

- [Getting started](../../../../docs/getting-started/dotnet.md)
- [API reference](../../../../docs/api-reference/dotnet.md)
- [Baseline requirement mapping](BASELINE_REQUIREMENT_MAPPING.md)

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

## Enterprise soak/fault harnesses

Deterministic mode:

```bash
bash artifacts/enterprise-readiness/run_dotnet_soak_suite.sh

# or per-ticket:
bash artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh
bash artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_failover_soak.sh
bash artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh
```

Runtime mode (requires live DSN):

```bash
DOTNET_HARNESS_MODE=runtime SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
bash artifacts/enterprise-readiness/run_dotnet_soak_suite.sh

# or per-ticket:
DOTNET_HARNESS_MODE=runtime SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
bash artifacts/enterprise-readiness/DOTNET-101/verification_dotnet_soak.sh

DOTNET_HARNESS_MODE=runtime SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
bash artifacts/enterprise-readiness/DOTNET-102/verification_dotnet_failover_soak.sh

DOTNET_HARNESS_MODE=runtime SCRATCHBIRD_DOTNET_URL='scratchbird://...' \
bash artifacts/enterprise-readiness/DOTNET-103/verification_dotnet_fault_matrix.sh
```
