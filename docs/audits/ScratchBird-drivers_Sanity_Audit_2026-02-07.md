# ScratchBird-drivers Sanity Audit
Date: 2026-02-07
Scope: ScratchBird-driver repo (drivers, integrations, CLI, specs) + full local build/test pass

## Executive Summary
- Documentation/wiki/specs aligned to current implementation and build/test outcomes; overstatements removed.
- Resilience modules are integrated across drivers (CircuitBreaker, Keepalive, LeakDetector, Telemetry); C/C++ statement cache added and wired into build.
- Core driver/CLI build and test passes are now green; remaining release blockers are toolchain gaps (Elixir 1.15+, Dart/Mojo), R check warnings, and Pascal TLS 1.3 support in Indy.

## Build/Test Results (2026-02-07)
Pass/Fail status is for the local environment; skipped tests are noted.

| Driver | Result | Details |
| --- | --- | --- |
| Go | PASS | `go test ./...` |
| Node.js | PASS | `npm test` (4 integration tests skipped: `SCRATCHBIRD_NODE_URL` not set) |
| Python | PASS | `pytest` in venv (4 integration tests skipped: `SCRATCHBIRD_TEST_DSN` not set) |
| Ruby | PASS | `ruby -Ilib:test test/test_types.rb` |
| Rust | PASS | `cargo test` (warnings: deprecated rustls, dead fields) |
| PHP | PASS | `vendor/bin/phpunit tests` (4 skipped) |
| .NET | PASS | `dotnet test` (nullability/hiding warnings) |
| Java/JDBC | PASS | `./gradlew build` with JDK 17 |
| Pascal | PASS (compile) | `fpc` compile passes; Indy 10 lacks TLS 1.3 so runtime connects are blocked |
| ODBC | PASS | `cmake --build build` (warnings: ODBC headers + GTest not found) |
| C/C++ | PASS | `cmake --build build` |
| Swift | PASS | `swift test` |
| Dart | NOT RUN | `dart` not installed |
| R | WARNINGS | `R CMD check` completes with warnings/notes (missing docs, replacement function arg name) |
| Elixir | FAIL | `mix test` fails (Elixir 1.15 required; system 1.14) |
| Mojo | NOT RUN | `mojo` not installed |
| CLI tools | PASS | `build_cli` builds core tools; OpenSSL 3 deprecation warnings. FDW tools remain gated |

## Key Findings / Gaps
- **Pascal**: Build passes with vendored Indy; TLS 1.3 missing in Indy 10 blocks runtime connections.
- **R**: `R CMD check` produces warnings/notes (documentation coverage, replacement function argument name, S3 generic/method consistency).
- **Elixir**: Toolchain version mismatch (Elixir 1.15+ required).
- **Dart/Mojo**: Toolchains not installed; CI bootstrap instructions added.
- **CLI tools**: Core tools build; FDW tools are gated pending adapters from engine repo.

## Remediation & Implementation Work Completed
- Integrated resilience modules across Node/Swift/Dart/Elixir.
- Implemented `tracks/p3/drivers/cpp/src/statement_cache.cpp` and wired into C++/ODBC builds.
- Added CLI build runner (`tracks/p3/drivers/cli/CMakeLists.txt`) and vendored missing headers from the engine repo.
- Added C++ client `Connection/ResultSet` shim for the CLI conformance runner.
- Updated JDBC Gradle wrapper to 8.5+; build now passes with JDK 17.
- Added Indy 10 vendoring for Pascal + TLS 1.3 gating to avoid unsafe fallback.
- Added `docs/development/toolchain-setup.md` for Dart/Mojo CI bootstrap.
- Created `docs/planning/P0_READINESS_CHECKLIST.md` derived from release targets.

## Documentation Updates
- README and wiki updated with the 2026-02-07 build/test snapshot and corrected status claims.
- `docs/BUILD_MATRIX.md` and `docs/development/build-and-test.md` updated with current build steps, including venv guidance and CLI tools.
- Driver wiki pages (Dart/Mojo/Elixir) updated with accurate toolchain notes.
- Release planning checklist added in `docs/planning/P0_READINESS_CHECKLIST.md`.

## Remaining Blockers Before First Public Release
1. Provide TLS 1.3-capable Indy build for Pascal (Indy 10 lacks TLS 1.3).
2. Resolve R `R CMD check` warnings (documentation coverage, replacement function arg name, generics).
3. Provide Elixir 1.15+ for `mix test`.
4. Ensure Dart/Mojo toolchains are available in CI or explicitly gated with install steps.
5. Decide whether FDW-backed CLI tools remain gated or receive adapter ports before release.

---
Report generated after static audit + runtime build/test pass.
