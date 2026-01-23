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

## Python

```bash
cd python
python -m pip install -e ".."
python -m pip install -e ".[test]"
pytest
```

Integration env:

- `SCRATCHBIRD_TEST_DSN`

## Node.js

```bash
cd node
npm install
npm test
```

Integration env:

- `SCRATCHBIRD_NODE_URL`

## Ruby

```bash
cd ruby
ruby -Ilib -e 'require "scratchbird"'
```

Integration env:

- `SCRATCHBIRD_RUBY_URL`

## Rust

```bash
cd rust
cargo test
```

Integration env:

- `SCRATCHBIRD_RUST_URL`

## PHP

```bash
cd php
composer install
vendor/bin/phpunit
```

Integration env:

- `SCRATCHBIRD_PHP_URL`

## R

```bash
cd r
R -q -e 'devtools::test()'
```

Integration env:

- `SCRATCHBIRD_R_URL`

## Pascal/Delphi

Run the test projects under `pascal/tests/` with:

- `SCRATCHBIRD_PASCAL_URL`

## .NET

```bash
cd dotnet
dotnet test
```

Integration env:

- `SCRATCHBIRD_DOTNET_URL`

## JDBC

```bash
cd jdbc
./gradlew test
```

Integration env:

- `SCRATCHBIRD_JDBC_URL`
- `SCRATCHBIRD_JDBC_USER`
- `SCRATCHBIRD_JDBC_PASSWORD`
