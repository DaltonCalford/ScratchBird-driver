# ScratchBird C/C++ Client (`libscratchbird_client`)

Native C/C++ client library for ScratchBird SBWP v1.1.

## Lane Docs

- [Baseline Requirement Mapping (S0)](./BASELINE_REQUIREMENT_MAPPING.md)
- [Build Matrix](docs/BUILD_MATRIX.md)

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

See `docs/BUILD_MATRIX.md` for toolchain prerequisites.
