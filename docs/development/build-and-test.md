# Build and Test Matrix

This repository builds each driver independently. Use the commands below from
repo root. Integration tests require a running ScratchBird server.

## Driver Runtime Stack

For integration checks against a real ScratchBird server + parser + listener
stack (from sibling `../ScratchBird`):

```bash
scripts/driver_runtime_stack.sh up
scripts/driver_runtime_stack.sh fixtures
eval "$(scripts/driver_runtime_stack.sh env)"
```

Stop stack:

```bash
scripts/driver_runtime_stack.sh down
```

Combined JDBC + ODBC runtime checks:

```bash
scripts/run_jdbc_odbc_runtime_checks.sh
```

## CI OS Coverage

Windows and Linux in CI:
- Go, Node.js, Python, Ruby, Rust, PHP, R, .NET, JDBC, Pascal, Dart
- C/C++ and ODBC
- Elixir
- CLI tools (Linux supported; Windows build attempt enabled)

Linux-only in CI:
- Swift
- Mojo (gated by `MOJO_ENABLED=true`)

## Go

```bash
cd tracks/p3/drivers/go

go test ./...
```

Integration env:

- `SCRATCHBIRD_GO_URL`
- `SCRATCHBIRD_GO_CANCEL_SQL`

## Python

```bash
cd tracks/p3/drivers/python
python -m pip install --upgrade pip
python -m pip install -e ".[test]"
python -m pytest
```

Integration env:

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_CANCEL_SQL`

## Node.js

```bash
cd tracks/p3/drivers/node
npm install
npm test
```

Integration env:

- `SCRATCHBIRD_NODE_URL`
- `SCRATCHBIRD_NODE_CANCEL_SQL`

## C/C++

```bash
cmake -S tracks/p3/drivers/cpp -B build-cpp -DCMAKE_BUILD_TYPE=Release
cmake --build build-cpp --config Release
```

## ODBC

```bash
cmake -S tracks/p3/drivers/odbc -B build-odbc -DCMAKE_BUILD_TYPE=Release
cmake --build build-odbc --config Release
```

Runtime verification command (after stack/env setup above):

```bash
cmake -S tracks/p3/drivers/odbc -B build/odbc-runtime -DCMAKE_BUILD_TYPE=Release -DBUILD_TESTING=ON -DODBC_FETCH_GTEST=ON
cmake --build build/odbc-runtime --config Release
ctest --test-dir build/odbc-runtime --output-on-failure -R '^scratchbird_odbc_tests$'
```

## CLI Tools

```bash
cmake -S . -B build_cli -DSB_BUILD_CLI=ON -DSB_BUILD_CPP=ON -DSB_BUILD_ODBC=OFF
cmake --build build_cli --config Release
```

Notes:
- `-DSB_BUILD_CLI_FDW=ON` builds `sb_pg_isql`, `sb_my_isql`, `sb_fb_isql` (requires FDW adapter implementations from the engine repo).
- Windows CI currently builds this target in experimental mode.

## Ruby

```bash
cd tracks/p3/drivers/ruby
ruby -Ilib:test test/*.rb
```

Integration env:

- `SCRATCHBIRD_RUBY_URL`
- `SCRATCHBIRD_RUBY_CANCEL_SQL`

## Rust

```bash
cd tracks/p3/drivers/rust
cargo test
```

Integration env:

- `SCRATCHBIRD_RUST_URL`
- `SCRATCHBIRD_RUST_CANCEL_SQL`

## PHP

```bash
cd tracks/p3/drivers/php
composer install
vendor/bin/phpunit
```

Integration env:

- `SCRATCHBIRD_PHP_URL`
- `SCRATCHBIRD_PHP_CANCEL_SQL`

## R

```bash
cd tracks/p3/drivers/r
R -q -e 'devtools::test()'
```

Integration env:

- `SCRATCHBIRD_R_URL`
- `SCRATCHBIRD_R_CANCEL_SQL`

## Elixir

```bash
cd tracks/p3/drivers/elixir
mix local.hex --force
mix local.rebar --force
mix deps.get
mix test
```

Windows note:
- Use the same `mix` commands in PowerShell after installing Elixir/OTP (`erlef/setup-beam` in CI).

Integration env:

- `SCRATCHBIRD_TEST_DSN`

## Dart

```bash
cd tracks/p3/drivers/dart
dart pub get
dart test
```

Integration env:

- `SCRATCHBIRD_TEST_DSN`

## Swift

```bash
cd tracks/p3/drivers/swift
swift test
```

Notes:
- CI currently validates Swift on Linux only.
- Windows is not a supported target in this repository yet.

## Mojo

```bash
cd tracks/p3/drivers/mojo/tests
mojo integration.mojo
```

Integration env:

- `SCRATCHBIRD_MOJO_URL`

## Pascal/Delphi

Run the test projects under `tracks/p3/drivers/pascal/tests/` with:

- `SCRATCHBIRD_PASCAL_URL`
- `SCRATCHBIRD_PASCAL_STREAM_SQL` (optional)
- `SCRATCHBIRD_PASCAL_GENERATED_KEY_SQL` (optional)
- `SCRATCHBIRD_PASCAL_GENERATED_KEY_EXPECTED` (optional)
- `SCRATCHBIRD_PASCAL_CANCEL_SQL`

## .NET

```bash
cd tracks/p3/drivers/dotnet
dotnet test
```

Integration env:

- `SCRATCHBIRD_DOTNET_URL`
- `SCRATCHBIRD_DOTNET_CANCEL_SQL`

## JDBC

```bash
cd tracks/p3/drivers/jdbc
./gradlew test
```

Windows:

```bash
cd tracks/p3/drivers/jdbc
gradlew.bat test
```

Integration env:

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`
- `SCRATCHBIRD_JDBC_CANCEL_SQL`

Runtime verification command (after stack/env setup above):

```bash
cd tracks/p3/drivers/jdbc
./gradlew test
```
