# Blocker Remediation Update (2026-02-07)

This report summarizes work completed and the current state of the remaining blockers for the first public release.

## Completed
- Ruby type constants added (`WIRE_ARRAY`, `WIRE_UUID`) + tests passing.
- Swift decode crash fixed; tests now pass.
- Pascal SCRAM Base64 dependency removed (pure Pascal Base64 + SHA256 added).
- JDBC build toolchain updated to Java 17 (Gradle 8.5+ wrapper); `./gradlew build` now succeeds with JDK 17.
- R `DESCRIPTION` DCF format fixed; license file added; imports updated.
- Elixir Hex bootstrap documented (now includes `mix local.hex --force` and `mix local.rebar --force`).
- C/C++ statement cache implemented and wired into C++/ODBC builds.
- CLI build runner added with new `tracks/alpha/drivers/cli/CMakeLists.txt`, C++ client `Connection/ResultSet` shim, CRC32C implementation, and JSON header vendored for conformance runner.
- Resilience modules added to Node/Swift/Dart/Elixir drivers and wired into their connection flows.
- CI toolchain bootstrap doc added for Dart/Mojo (`docs/development/toolchain-setup.md`).

## Build/Test Pass (Local)
- Go: `go test ./...` pass.
- Node: `npm test` pass (4 integration tests skipped: `SCRATCHBIRD_NODE_URL` not set).
- Python: `pytest` pass in venv (4 integration tests skipped: `SCRATCHBIRD_TEST_DSN` not set).
- Ruby: `ruby -Ilib:test test/test_types.rb` pass.
- Rust: `cargo test` pass (warnings: deprecated rustls, dead fields).
- PHP: `vendor/bin/phpunit tests` pass (4 skipped).
- .NET: `dotnet test` pass (warnings: nullability/hiding).
- ODBC: `cmake --build build` pass (warns: ODBC headers + GTest not found).
- C/C++: `cmake --build build` pass (no hard errors).
- Swift: `swift test` pass.
- CLI tools: `build_cli` pass for `sb_isql`, `sb_admin`, `sb_backup`, `sb_security`, `sb_verify`, `sbdriver_conformance` (OpenSSL 3 deprecation warnings).

## Build/Test Failures or Gaps
- Pascal: FPC compile passes with vendored Indy, but Indy 10 lacks TLS 1.3 support; driver refuses to connect without a TLS 1.3-capable Indy build.
- R: `R CMD check` completes with warnings/notes (missing documentation entries, replacement function arg name, generic/method consistency). No hard errors, but cleanup is required for release quality.
- Elixir: `mix test` fails (Elixir ~>1.15 required; system is 1.14).
- Dart: `dart` not installed.
- Mojo: `mojo` not installed.
- CLI FDW tools (`sb_pg_isql`, `sb_my_isql`, `sb_fb_isql`) remain gated behind `SB_BUILD_CLI_FDW=ON` until FDW adapters are ported from the engine repo.

## Remaining Release Blockers
1. Provide TLS 1.3-capable Indy build for Pascal (current Indy 10 lacks TLS 1.3).
2. Resolve R `R CMD check` warnings (documentation coverage, replacement function arg name, generics).
3. Provide Elixir 1.15+ for `mix test`.
4. Ensure Dart/Mojo toolchains are available in CI or explicitly gated with install steps.
5. Decide whether FDW-backed CLI tools remain gated or receive adapter ports before release.
