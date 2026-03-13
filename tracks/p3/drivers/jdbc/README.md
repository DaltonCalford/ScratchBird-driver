# ScratchBird JDBC Driver

Pure Java (Type 4) driver for ScratchBird.

## Documentation

- [Getting started](../../../../docs/getting-started/jdbc.md)
- [API reference](../../../../docs/api-reference/jdbc.md)
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
./gradlew build
```

Windows:

```cmd
gradlew.bat build
```

## Tests

```bash
./gradlew test
```

Windows:

```cmd
gradlew.bat test
```

Integration env:

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`
