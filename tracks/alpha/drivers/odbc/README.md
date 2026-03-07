# ScratchBird ODBC Driver (ODBC 3.8)

ODBC 3.8 driver for ScratchBird SBWP v1.1.

## Documentation

- [Getting started](../../../../docs/getting-started/odbc.md)
- [API reference](../../../../docs/api-reference/odbc.md)
- [Connectivity guide](../../../../docs/user-documentation/connectivity/odbc.md)
- [Baseline mapping](BASELINE_REQUIREMENT_MAPPING.md)

## Platform Support

| Platform | Status | Notes |
|----------|--------|-------|
| Linux | Supported | CI build coverage. |
| Windows | Supported | CI build coverage. |
| macOS | Untested | Not currently covered in CI. |

## Build

```bash
cmake -S . -B build
cmake --build build --config Release
```

See `docs/BUILD_MATRIX.md` for required ODBC/OpenSSL dependencies.

## Connection Strings

Direct/native:

```ini
Driver={ScratchBird};Server=127.0.0.1;Port=3092;Database=mydb;UID=user;PWD=pass;SSLMode=prefer
```

Manager-proxy:

```ini
Driver={ScratchBird};Server=127.0.0.1;Port=3090;Database=mydb;UID=user;PWD=pass;FrontDoorMode=manager_proxy;ManagerAuthToken=token
```

## Baseline Mapping

See [BASELINE_REQUIREMENT_MAPPING.md](BASELINE_REQUIREMENT_MAPPING.md) for S0 ODBCBL-to-JDBC baseline status and evidence anchors.
