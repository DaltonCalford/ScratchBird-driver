# Development Notes

These notes cover build workflows and contributor expectations for the driver
repository. Test instructions live in the build-and-test guide.

## Building All Drivers

Each driver has its own build process. Use these commands from repo root:

```bash
# C/C++ + ODBC + CLI tools
cmake -S . -B build
cmake --build build

# Go
cd go && go build ./...

# Python
cd python && pip install -e .

# Node.js
cd node && npm install && npm run build

# Rust
cd rust && cargo build

# .NET
cd dotnet && dotnet build

# JDBC
cd jdbc && ./gradlew build
```

## Development Requirements

1. Follow the coding style of each language.
2. Include tests for new features.
3. Update documentation.
4. Ensure CI passes before submitting PRs.

## Tests

See [Build and test matrix](build-and-test.md) for driver test commands and
integration environment variables.
