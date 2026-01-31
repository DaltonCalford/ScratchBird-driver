# Development

Build, test, and release commands for all ScratchBird drivers.

## Build and Test

Integration tests require a running ScratchBird server.

### Go

```bash
cd go
go test ./...
```

Env: `SCRATCHBIRD_GO_URL`

### Python

```bash
cd python
python -m pip install -e ".[test]"
pytest
```

Env: `SCRATCHBIRD_TEST_DSN`

### Node.js

```bash
cd node
npm install
npm test
```

Env: `SCRATCHBIRD_NODE_URL`

### Ruby

```bash
cd ruby
bundle install
rake test
```

Env: `SCRATCHBIRD_RUBY_URL`

### Rust

```bash
cd rust
cargo test
```

Env: `SCRATCHBIRD_RUST_URL`

### PHP

```bash
cd php
composer install
vendor/bin/phpunit
```

Env: `SCRATCHBIRD_PHP_URL`

### R

```bash
cd r
R -q -e 'devtools::test()'
```

Env: `SCRATCHBIRD_R_URL`

### Pascal/Delphi

Run test projects under `pascal/tests/`.

Env: `SCRATCHBIRD_PASCAL_URL`

### .NET

```bash
cd dotnet
dotnet test
```

Env: `SCRATCHBIRD_DOTNET_URL`

### JDBC

```bash
cd jdbc
./gradlew test
```

Env: `SCRATCHBIRD_JDBC_URL`, `SCRATCHBIRD_JDBC_USER`, `SCRATCHBIRD_JDBC_PASSWORD`

---

## Release Packaging

### Go

Tag releases and rely on Go module versioning.

```bash
git tag v0.1.0
git push origin v0.1.0
```

Module path: `github.com/scratchbird/scratchbird-go`

### Python

```bash
cd python
python -m pip install build twine
python -m build
twine upload dist/*
```

### Node.js

```bash
cd node
npm run build
npm publish
```

### Ruby

```bash
cd ruby
gem build scratchbird.gemspec
gem push scratchbird-0.1.0.gem
```

### Rust

```bash
cd rust
cargo publish
```

### PHP

Use Composer package publishing (Packagist).

### R

```bash
R CMD build .
R CMD check scratchbird_0.1.0.tar.gz
```

Then publish to CRAN or target repository.

### .NET

```bash
cd dotnet
dotnet pack
dotnet nuget push bin/Release/*.nupkg
```

### JDBC

```bash
cd jdbc
./gradlew publish
```

### Metabase Plugin

```bash
cd scratchbird-metabase-driver
clj -T:build jar
```

Distribute the JAR with `metabase-plugin.yaml` embedded.

### Superset Dialect

```bash
cd scratchbird-superset-driver
pip install build
python -m build
pip install dist/*.whl
```

---

## Cross-Platform CI

Build and test commands are documented for both Windows and Linux in `docs/BUILD_MATRIX.md`.

**Last Updated:** 2026-01-30
