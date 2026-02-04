# Language Driver Templates

Status: Draft (Template)

This directory contains per-language driver specification templates for all
Alpha/Beta target drivers referenced in the ScratchBird specifications.

## Target Drivers (Alpha/Beta)

- `tracks/beta/drivers/cpp/` - C/C++
- `dotnet-csharp/` - .NET/C#
- `golang/` - Go
- `java-jdbc/` - Java JDBC
- `nodejs-typescript/` - Node.js/TypeScript
- `pascal-delphi/` - Pascal/Delphi/FreePascal
- `tracks/alpha/drivers/php/` - PHP
- `tracks/alpha/drivers/python/` - Python
- `tracks/beta/drivers/r/` - R
- `tracks/alpha/drivers/ruby/` - Ruby
- `tracks/alpha/drivers/rust/` - Rust

## Source List

- `TARGETS_FROM_SCRATCHBIRD.md`

## Template Files

Each driver template includes:

- `README.md`
- `SPECIFICATION.md`
- `API_REFERENCE.md`
- `COMPATIBILITY_MATRIX.md`
- `IMPLEMENTATION_PLAN.md`
- `MIGRATION_GUIDE.md`
- `TESTING_CRITERIA.md`

## How to Use

1. Copy the template into the driver’s implementation plan or spec area.
2. Fill in language-specific APIs and constraints.
3. Link directly to shared requirements in `docs/specifications/`.
