# Driver Build Requirements & Matrix (Windows/Linux)

All drivers in this repo are userland implementations of SBWP v1.1 unless noted.
Build commands are identical across Windows/Linux unless noted.

Common requirements:
- ScratchBird server for integration tests (native listener on 3092).
- Compiler toolchain (`gcc/clang`, `make`, and standard headers) for native dependencies.
- Set driver-specific `SCRATCHBIRD_*` environment variables as documented in each README.

## Go (`go/`)
- Required tools: Go 1.22+.
- Build/test: `go test ./...`

## Node.js (`node/`)
- Required tools: Node.js 20+ and npm.
- Install/build/test:
  - `npm install`
  - `npm run build`
  - `npm test`

## Python (`python/`)
- Required tools: Python 3.11+ and pip.
- Install/test:
  - `python -m pip install -e ".[test]"`
  - `python -m pytest`

## Ruby (`ruby/`)
- Required tools: Ruby 3.2+ and RubyGems.
- Build/install:
  - `gem build scratchbird.gemspec`
  - `gem install scratchbird-*.gem`
- Test: `ruby -Ilib test/*.rb`

## Rust (`rust/`)
- Required tools: Rust 1.76+ (cargo).
- Build/test:
  - `cargo build`
  - `cargo test`

## PHP (`php/`)
- Required tools: PHP 8.2+ and Composer.
- Install/test:
  - `composer install`
  - `vendor/bin/phpunit tests`

## R (`r/`)
- Required tools: R 4.3+.
- Build/check:
  - `R CMD build .`
  - `R CMD check scratchbird_*.tar.gz`

## Pascal (`pascal/`)
- Required tools:
  - FreePascal 3.2+ or Delphi 11+.
- FreePascal: include units from `src/` in your project and compile with `fpc`.
- Delphi: add units in `src/` to the project.
- No automated test runner yet.

## .NET (`dotnet/`)
- Required tools: .NET SDK 8.0+.
- Build/test:
  - `dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj`
  - `dotnet test`

## Java/JDBC (`jdbc/`)
- Required tools: JDK 17+ and Gradle.
- Linux/macOS: `./gradlew build`
- Windows: `gradlew.bat build`

## ODBC (`odbc/`)
- Required tools:
  - CMake 3.22+, C/C++ compiler.
  - ODBC headers (e.g., unixODBC-dev on Linux).
- Build:
  - `cmake -S . -B build`
  - `cmake --build build`

## C/C++ (`cpp/`)
- Required tools: CMake 3.22+, C/C++ compiler.
- Build:
  - `cmake -S . -B build`
  - `cmake --build build`

## Dart (`dart/`)
- Required tools: Dart 3.3+ (Flutter SDK also works).
- Build/test:
  - `dart pub get`
  - `dart test`

## Swift (`swift/`)
- Required tools: Swift 5.10+ (SwiftPM), plus a C toolchain for dependencies.
- Build/test:
  - `swift build`
  - `swift test`

## Elixir (`elixir/`)
- Required tools: Elixir 1.15+ and Erlang/OTP 26+.
- Build/test:
  - `mix deps.get`
  - `mix test`

## Mojo (`mojo/`)
- Required tools: Mojo 24.4+ (Python is used for the bridge).
- Build/test:
  - `mojo test -I src tests`

## CLI Tools (`cli/`)
- Required tools: Go 1.22+ (for the native/equivalent protocol runners).
- Build/test:
  - `go test ./...`
