# Driver Build Requirements & Matrix (Windows/Linux)

Core drivers in this repo are userland implementations of SBWP v1.1; Mojo currently uses a Python transport bridge.
Build commands are identical across Windows/Linux unless noted.

Common requirements:
- ScratchBird server for integration tests (native listener on 3092).
- Compiler toolchain (`gcc/clang`, `make`, and standard headers) for native dependencies.
- Set driver-specific `SCRATCHBIRD_*` environment variables as documented in each README.

## CI Platform Coverage (Driver CI)

Verified in GitHub Actions on both `ubuntu-latest` and `windows-latest`:
- Go, Node.js, Python, Ruby, Rust, PHP, R, .NET, JDBC, Pascal, Dart
- C/C++ client (`tracks/p3/drivers/cpp`)
- ODBC driver (`tracks/p3/drivers/odbc`)
- Elixir (in-development track)
- CLI tools: Linux supported; Windows build attempt enabled (experimental)

Linux-only CI coverage:
- Swift (no official Windows Swift toolchain support in this repo)
- Mojo (gated by `MOJO_ENABLED=true`)

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
  r-cran-dbi r-cran-openssl r-cran-testthat \
  fp-compiler lazarus lazarus-src \
  dotnet-sdk-8.0 \
  openjdk-17-jdk gradle \
  elixir erlang \
  sqlite3`

Notes:
- Dart, Swift, and Mojo are not available via Ubuntu apt; install via their official channels.
- Ubuntu repos may not include Node 20+ or Rust 1.76+; use NodeSource/rustup when needed.

## Build/Test Snapshot (2026-02-07)

Results from a full local pass (Ubuntu 24.04). This is not a release certification.

- Go: `go test ./...` pass.
- Node: `npm test` pass; 4 integration tests skipped (`SCRATCHBIRD_NODE_URL` not set).
- Python: `pytest` pass in venv; 4 integration tests skipped (`SCRATCHBIRD_TEST_DSN` not set).
- Ruby: `ruby -Ilib:test test/test_types.rb` pass. Integration tests skipped (no `SCRATCHBIRD_RUBY_URL`).
- Rust: `cargo test` pass (warnings: deprecated rustls, dead fields).
- PHP: `vendor/bin/phpunit tests` pass; 4 tests skipped.
- .NET: `dotnet test` pass (warnings: nullability/hiding).
- Java/JDBC: `./gradlew build` pass (JDK 17 required; build ran with `JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64`).
- Pascal: `fpc` compile passes with vendored Indy (warnings). TLS 1.3 is not available in Indy 10; driver will refuse to connect unless a TLS 1.3-capable Indy build is provided.
- ODBC: `cmake --build` pass; warns ODBC headers + GTest not found.
- C/C++: `cmake --build` pass.
- Swift: `swift test` pass.
- Dart: not run (`dart` not installed).
- R: `R CMD check` completes with warnings/notes (missing documentation entries, replacement function arg name, generic/method consistency).
- Elixir: `mix test` fails (requires Elixir ~> 1.15; system 1.14).
- Mojo: not run (`mojo` not installed).
- CLI tools: build passes for `sb_isql`, `sb_admin`, `sb_backup`, `sb_security`, `sb_verify`, `sbdriver_conformance` (OpenSSL 3 deprecation warnings). FDW-backed tools (`sb_pg_isql`, `sb_my_isql`, `sb_fb_isql`) are gated behind `SB_BUILD_CLI_FDW=ON`.
- 2026-02-18 sanity checks: direct CMake builds for C/C++, ODBC, and CLI succeed on Linux using the documented CI commands.

## Go (`tracks/p3/drivers/go/`)
- Required tools: Go 1.22+.
- Ubuntu 24.04 packages: `sudo apt install -y golang-go`
- Build/test: `go test ./...`

## Node.js (`tracks/p3/drivers/node/`)
- Required tools: Node.js 20+ and npm.
- Ubuntu 24.04 packages: `sudo apt install -y nodejs npm`
  - Note: Ubuntu repo may ship Node 18; use NodeSource if you need 20+.
- Install/build/test:
  - `npm install`
  - `npm run build`
  - `npm test`

## Python (`tracks/p3/drivers/python/`)
- Required tools: Python 3.11+ and pip.
- Ubuntu 24.04 packages: `sudo apt install -y python3.11 python3.11-venv python3-pip`
- Install/test:
  - `python3 -m venv .venv`
  - `. .venv/bin/activate`
  - `python -m pip install -e ".[test]"`
  - `python -m pytest`

## Ruby (`tracks/p3/drivers/ruby/`)
- Required tools: Ruby 3.2+ and RubyGems.
- Ubuntu 24.04 packages: `sudo apt install -y ruby-full`
- Build/install:
  - `gem build scratchbird.gemspec`
  - `gem install scratchbird-*.gem`
- Test: `ruby -Ilib test/*.rb`
  - Tip: include the test directory on the load path: `ruby -Ilib:test test/*.rb`

## Rust (`tracks/p3/drivers/rust/`)
- Required tools: Rust 1.76+ (cargo).
- Ubuntu 24.04 packages: `sudo apt install -y rustc cargo`
  - Note: apt Rust may lag; use `rustup` if you need 1.76+.
- Build/test:
  - `cargo build`
  - `cargo test`

## PHP (`tracks/p3/drivers/php/`)
- Required tools: PHP 8.2+ and Composer.
- Ubuntu 24.04 packages: `sudo apt install -y php8.2 php8.2-cli php8.2-mbstring php8.2-xml php8.2-curl php8.2-zip composer`
- Install/test:
  - `composer install`
  - `vendor/bin/phpunit tests`

## R (`tracks/p3/drivers/r/`)
- Required tools: R 4.3+.
- Ubuntu 24.04 packages: `sudo apt install -y r-base r-base-dev r-cran-dbi r-cran-openssl r-cran-testthat`
- R packages (if not using apt): `install.packages(c("DBI", "openssl", "testthat"))`
- Build/check:
  - `R CMD build .`
  - `R CMD check scratchbird_*.tar.gz`

## Pascal (`tracks/p3/drivers/pascal/`)
- Required tools:
  - FreePascal 3.2+ or Delphi 11+.
- Default build path uses in-repo native transport/TLS units and requires OpenSSL runtime libraries (`libssl`/`libcrypto`).
- Native TLS status (`0.1.0`): native runtime TLS transport is implemented with
  OpenSSL for handshake/read/write and `sslmode` policy enforcement (including
  `verify-full` hostname checks).
- Optional legacy path: define `SCRATCHBIRD_USE_INDY` and add vendored Indy unit paths
  (`third_party/indy/Lib/Core`, `Lib/Protocols`, `Lib/System`, `Lib/Security`) for migration-only builds.
- FreePascal: include units from `src/` and compile with `fpc`.
- Delphi: add units in `src/` to the project.
- Unit test program available:
  - `fpc -Mdelphi -Fu./tracks/p3/drivers/pascal/src -FE./tracks/p3/drivers/pascal/tests ./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests.pas`
  - `./tracks/p3/drivers/pascal/tests/TlsCryptoAndPolicyTests`

## .NET (`tracks/p3/drivers/dotnet/`)
- Required tools: .NET SDK 8.0+.
- Ubuntu 24.04 packages: `sudo apt install -y dotnet-sdk-8.0`
- Build/test:
  - `dotnet build src/ScratchBird.Data/ScratchBird.Data.csproj`
  - `dotnet test`

## Java/JDBC (`tracks/p3/drivers/jdbc/`)
- Required tools: JDK 17+ and Gradle.
- Ubuntu 24.04 packages: `sudo apt install -y openjdk-17-jdk gradle`
- If building on JDK 21+, use Gradle 8.5+ (wrapper is pinned accordingly).
- Linux/macOS: `./gradlew build`
- Windows: `gradlew.bat build`

## ODBC (`tracks/p3/drivers/odbc/`)
- Required tools:
  - CMake 3.22+, C/C++ compiler.
  - ODBC headers (e.g., unixODBC-dev on Linux).
- Ubuntu 24.04 packages: `sudo apt install -y unixodbc-dev`
- Build:
  - `cmake -S . -B build`
  - `cmake --build build`
- Windows:
  - `cmake -S . -B build`
  - `cmake --build build --config Release`

## C/C++ (`tracks/p3/drivers/cpp/`)
- Required tools: CMake 3.22+, C/C++ compiler.
- Ubuntu 24.04 packages: `sudo apt install -y build-essential cmake`
- Build:
  - `cmake -S . -B build`
  - `cmake --build build`
- Windows:
  - `cmake -S . -B build`
  - `cmake --build build --config Release`

## Dart (`tracks/p3/drivers/dart/`)
- Required tools: Dart 3.3+ (Flutter SDK also works).
- Ubuntu 24.04 packages: `dart` (from the Dart apt repo), or install via Flutter SDK.
- CI bootstrap: see `docs/development/toolchain-setup.md`.
- Build/test:
  - `dart pub get`
  - `dart test`

## Swift (`tracks/p3/drivers/swift/`)
- Required tools: Swift 5.10+ (SwiftPM), plus a C toolchain for dependencies.
- Ubuntu 24.04 packages: not available via apt; install Swift from swift.org or use `swiftly`.
- Build/test:
  - `swift build`
  - `swift test`
- Windows note: no official support target in this repository yet.

## Elixir (`tracks/p3/drivers/elixir/`)
- Required tools: Elixir 1.15+ and Erlang/OTP 26+.
- Ubuntu 24.04 packages: `sudo apt install -y elixir erlang`
- Build/test:
  - `mix local.hex --force`
  - `mix local.rebar --force`
  - `mix deps.get`
  - `mix test`
- CI uses Elixir `1.15.x` with OTP `26.x` on Linux and Windows.

## Mojo (`tracks/p3/drivers/mojo/`)
- Required tools: Mojo 24.4+ (Python is used for the bridge).
- Ubuntu 24.04 packages: not available via apt; install from Modular (Mojo).
- CI bootstrap: see `docs/development/toolchain-setup.md`.
- Build/test:
  - `mojo test -I src tests`
  - CI gating: set `MOJO_ENABLED=true` and ensure `mojo` is on PATH.

## CLI Tools (`tracks/p3/drivers/cli/`)
- Required tools: C++17 toolchain + OpenSSL.
- Build/test:
  - `cmake -S . -B build_cli -DSB_BUILD_CLI=ON -DSB_BUILD_CPP=ON -DSB_BUILD_ODBC=OFF`
  - `cmake --build build_cli`
  - Windows CI uses `cmake --build build_cli --config Release` (experimental coverage).
  - Optional: `-DSB_BUILD_CLI_FDW=ON` builds `sb_pg_isql`, `sb_my_isql`, `sb_fb_isql` (requires FDW adapter implementations from the engine repo).
  - `sbdriver_conformance` uses a vendored `nlohmann/json.hpp` header.
