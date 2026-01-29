# Driver Build Matrix (Windows/Linux)

All drivers in this repo are pure userland implementations of SBWP v1.1.
Build commands are identical across Windows/Linux unless noted.

Common requirements:
- ScratchBird server for integration tests (native listener on 3092).
- Set driver-specific `SCRATCHBIRD_*` environment variables as documented in each README.

## Go (`go/`)
- Build/test: `go test ./...`

## Node.js (`node/`)
- Install/build/test:
  - `npm install`
  - `npm run build`
  - `npm test`

## Python (`python/`)
- Install/test:
  - `python -m pip install -e ".[test]"`
  - `python -m pytest`

## Ruby (`ruby/`)
- Build/install:
  - `gem build scratchbird.gemspec`
  - `gem install scratchbird-*.gem`
- Test: `ruby -Ilib test/*.rb`

## Rust (`rust/`)
- Build/test:
  - `cargo build`
  - `cargo test`

## PHP (`php/`)
- Install/test:
  - `composer install`
  - `vendor/bin/phpunit tests`

## R (`r/`)
- Build/check:
  - `R CMD build .`
  - `R CMD check scratchbird_*.tar.gz`

## Pascal (`pascal/`)
- FreePascal: include units from `src/` in your project and compile with `fpc`.
- Delphi: add units in `src/` to the project.
- No automated test runner yet.

## .NET (`dotnet/`)
- Build/test:
  - `dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj`
  - `dotnet test`

## Java/JDBC (`jdbc/`)
- Linux/macOS: `./gradlew build`
- Windows: `gradlew.bat build`
