# Build and Test Matrix

This repository builds each driver independently. Use the commands below from
repo root. Integration tests require a running ScratchBird server.

## Go

```bash
cd go

go test ./...
```

Integration env:

- `SCRATCHBIRD_GO_URL`
- `SCRATCHBIRD_GO_CANCEL_SQL`

## Python

```bash
cd python
python -m pip install -e ".."
python -m pip install -e ".[test]"
pytest
```

Integration env:

- `SCRATCHBIRD_TEST_DSN`
- `SCRATCHBIRD_TEST_CANCEL_SQL`

## Node.js

```bash
cd node
npm install
npm test
```

Integration env:

- `SCRATCHBIRD_NODE_URL`
- `SCRATCHBIRD_NODE_CANCEL_SQL`

## Ruby

```bash
cd ruby
ruby -Ilib -e 'require "scratchbird"'
```

Integration env:

- `SCRATCHBIRD_RUBY_URL`
- `SCRATCHBIRD_RUBY_CANCEL_SQL`

## Rust

```bash
cd rust
cargo test
```

Integration env:

- `SCRATCHBIRD_RUST_URL`
- `SCRATCHBIRD_RUST_CANCEL_SQL`

## PHP

```bash
cd php
composer install
vendor/bin/phpunit
```

Integration env:

- `SCRATCHBIRD_PHP_URL`
- `SCRATCHBIRD_PHP_CANCEL_SQL`

## R

```bash
cd r
R -q -e 'devtools::test()'
```

Integration env:

- `SCRATCHBIRD_R_URL`
- `SCRATCHBIRD_R_CANCEL_SQL`

## Pascal/Delphi

Run the test projects under `pascal/tests/` with:

- `SCRATCHBIRD_PASCAL_URL`
- `SCRATCHBIRD_PASCAL_CANCEL_SQL`

## .NET

```bash
cd dotnet
dotnet test
```

Integration env:

- `SCRATCHBIRD_DOTNET_URL`
- `SCRATCHBIRD_DOTNET_CANCEL_SQL`

## JDBC

```bash
cd jdbc
./gradlew test
```

Integration env:

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`
- `SCRATCHBIRD_JDBC_CANCEL_SQL`
