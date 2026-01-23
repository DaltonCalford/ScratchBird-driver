# Packaging and Release

This repository ships multiple language packages. Use the language-native
packaging tools below.

## Go

- Module path: `github.com/scratchbird/scratchbird-go`
- Tag releases and rely on Go module versioning.

## Python

```bash
cd python
python -m pip install build
twine upload dist/*
```

## Node.js

```bash
cd node
npm run build
npm publish
```

## Ruby

```bash
cd ruby
gem build scratchbird.gemspec
gem push scratchbird-0.1.0.gem
```

## Rust

```bash
cd rust
cargo publish
```

## PHP

Use Composer package publishing (packagist).

## R

Use `R CMD build` and `R CMD check`, then publish to the target repository.

## .NET

```bash
cd dotnet
dotnet pack
```

## JDBC

```bash
cd jdbc
./gradlew publish
```

## Metabase Plugin

Build the plugin JAR in `scratchbird-metabase-driver` and distribute the JAR
with `metabase-plugin.yaml` embedded.
