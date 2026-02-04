# Driver Build Requirements & Matrix (Windows/Linux)

All drivers in this repo are userland implementations of SBWP v1.1 unless noted.
Build commands are identical across Windows/Linux unless noted.

Common requirements:
- ScratchBird server for integration tests (native listener on 3092).
- Compiler toolchain (`gcc/clang`, `make`, and standard headers) for native dependencies.
- Set driver-specific `SCRATCHBIRD_*` environment variables as documented in each README.

Ubuntu 24.04 baseline packages:
- `sudo apt install -y build-essential cmake pkg-config git`

Ubuntu 24.04 quick-install (full stack + nice-to-have tools):
- `sudo apt install -y build-essential cmake pkg-config git clang lld ninja-build \
  gdb lcov gcovr valgrind \
  unixodbc-dev openssl libssl-dev \
  golang-go nodejs npm \
  python3.11 python3.11-venv python3-pip \
  ruby-full \
  rustc cargo \
  php8.2 php8.2-cli php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip composer \
  r-base r-base-dev \
  fp-compiler \
  dotnet-sdk-8.0 \
  openjdk-17-jdk gradle \
  elixir erlang \
  sqlite3`

Notes:
- Dart, Swift, and Mojo are not available via Ubuntu apt; install via their official channels.
- Ubuntu repos may not include Node 20+ or Rust 1.76+; use NodeSource/rustup when needed.

## Go (`go/`)
- Required tools: Go 1.22+.
- Ubuntu 24.04 packages: `sudo apt install -y golang-go`
- Build/test: `go test ./...`

## Node.js (`node/`)
- Required tools: Node.js 20+ and npm.
- Ubuntu 24.04 packages: `sudo apt install -y nodejs npm`
  - Note: Ubuntu repo may ship Node 18; use NodeSource if you need 20+.
- Install/build/test:
  - `npm install`
  - `npm run build`
  - `npm test`

## Python (`python/`)
- Required tools: Python 3.11+ and pip.
- Ubuntu 24.04 packages: `sudo apt install -y python3.11 python3.11-venv python3-pip`
- Install/test:
  - `python -m pip install -e ".[test]"`
  - `python -m pytest`

## Ruby (`ruby/`)
- Required tools: Ruby 3.2+ and RubyGems.
- Ubuntu 24.04 packages: `sudo apt install -y ruby-full`
- Build/install:
  - `gem build scratchbird.gemspec`
  - `gem install scratchbird-*.gem`
- Test: `ruby -Ilib test/*.rb`

## Rust (`rust/`)
- Required tools: Rust 1.76+ (cargo).
- Ubuntu 24.04 packages: `sudo apt install -y rustc cargo`
  - Note: apt Rust may lag; use `rustup` if you need 1.76+.
- Build/test:
  - `cargo build`
  - `cargo test`

## PHP (`php/`)
- Required tools: PHP 8.2+ and Composer.
- Ubuntu 24.04 packages: `sudo apt install -y php8.2 php8.2-cli php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip composer`
- Install/test:
  - `composer install`
  - `vendor/bin/phpunit tests`

## R (`r/`)
- Required tools: R 4.3+.
- Ubuntu 24.04 packages: `sudo apt install -y r-base r-base-dev`
- Build/check:
  - `R CMD build .`
  - `R CMD check scratchbird_*.tar.gz`

## Pascal (`pascal/`)
- Required tools:
  - FreePascal 3.2+ or Delphi 11+.
- Ubuntu 24.04 packages (FreePascal): `sudo apt install -y fp-compiler`
- FreePascal: include units from `src/` in your project and compile with `fpc`.
- Delphi: add units in `src/` to the project.
- No automated test runner yet.

## .NET (`dotnet/`)
- Required tools: .NET SDK 8.0+.
- Ubuntu 24.04 packages: `sudo apt install -y dotnet-sdk-8.0`
- Build/test:
  - `dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj`
  - `dotnet test`

## Java/JDBC (`jdbc/`)
- Required tools: JDK 17+ and Gradle.
- Ubuntu 24.04 packages: `sudo apt install -y openjdk-17-jdk gradle`
- Linux/macOS: `./gradlew build`
- Windows: `gradlew.bat build`

## ODBC (`odbc/`)
- Required tools:
  - CMake 3.22+, C/C++ compiler.
  - ODBC headers (e.g., unixODBC-dev on Linux).
- Ubuntu 24.04 packages: `sudo apt install -y unixodbc-dev`
- Build:
  - `cmake -S . -B build`
  - `cmake --build build`

## C/C++ (`cpp/`)
- Required tools: CMake 3.22+, C/C++ compiler.
- Ubuntu 24.04 packages: `sudo apt install -y build-essential cmake`
- Build:
  - `cmake -S . -B build`
  - `cmake --build build`

## Dart (`dart/`)
- Required tools: Dart 3.3+ (Flutter SDK also works).
- Ubuntu 24.04 packages: `dart` (from the Dart apt repo), or install via Flutter SDK.
- Build/test:
  - `dart pub get`
  - `dart test`

## Swift (`swift/`)
- Required tools: Swift 5.10+ (SwiftPM), plus a C toolchain for dependencies.
- Ubuntu 24.04 packages: not available via apt; install Swift from swift.org or use `swiftly`.
- Build/test:
  - `swift build`
  - `swift test`

## Elixir (`elixir/`)
- Required tools: Elixir 1.15+ and Erlang/OTP 26+.
- Ubuntu 24.04 packages: `sudo apt install -y elixir erlang`
- Build/test:
  - `mix deps.get`
  - `mix test`

## Mojo (`mojo/`)
- Required tools: Mojo 24.4+ (Python is used for the bridge).
- Ubuntu 24.04 packages: not available via apt; install from Modular (Mojo).
- Build/test:
  - `mojo test -I src tests`

## CLI Tools (`cli/`)
- Required tools: Go 1.22+ (for the native/equivalent protocol runners).
- Ubuntu 24.04 packages: `sudo apt install -y golang-go`
- Build/test:
  - `go test ./...`
