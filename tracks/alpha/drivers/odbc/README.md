# ScratchBird ODBC Driver (ODBC 3.8)

ODBC 3.8 driver for ScratchBird SBWP v1.1.

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
