# Packaging and Release

This repository ships multiple language packages. Use the language-native
packaging tools below.

## Go

- Module path: `github.com/scratchbird/scratchbird-go`
- Tag releases and rely on Go module versioning.

## Python

```bash
cd tracks/p3/drivers/python
python -m pip install build
twine upload dist/*
```

## Node.js

```bash
cd tracks/p3/drivers/node
npm run build
npm publish
```

## Ruby

```bash
cd tracks/p3/drivers/ruby
gem build scratchbird.gemspec
gem push scratchbird-0.1.0.gem
```

## Rust

```bash
cd tracks/p3/drivers/rust
cargo publish
```

## PHP

Use Composer package publishing (packagist).

## R

Use `R CMD build` and `R CMD check`, then publish to the target repository.

## .NET

```bash
cd tracks/p3/drivers/dotnet
dotnet pack
```

## JDBC

```bash
cd tracks/p3/drivers/jdbc
./gradlew publish
```

## Metabase Plugin

Build the plugin JAR in `tracks/alpha/integrations/scratchbird-metabase-driver` and distribute the JAR
with `metabase-plugin.yaml` embedded.
