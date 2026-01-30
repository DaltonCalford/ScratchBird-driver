# Driver Conformance Checklist (SBWP v1.1)

Status: Draft
Last Updated: 2026-01-09
Scope: All drivers in this repo (native ScratchBird only)

## Manifest Reference

- Manifest: `docs/fixtures/sbwp_conformance_manifest.json`
- Fixtures: `docs/fixtures/core_fixture.sql`, `docs/fixtures/types_fixture.sql`

Required checks per manifest:
- handshake (query)
- auth
- prepare_bind
- describe_param_mismatch
- types_one_way
- paging_basic_table
- cancel_stream (env-gated)

Notes:
- Auth is validated implicitly by a successful connection in integration tests.
- Each integration test assumes the fixtures are loaded into the target database.
- cancel_stream requires `SCRATCHBIRD_CONFORMANCE_CANCEL=1` when using the
  manifest harness.

## Per-Driver Checklist

Go
- handshake: `go/integration_test.go`
- auth: implicit via connection
- prepare_bind: `go/integration_test.go`
- types_one_way: `go/integration_test.go`
- manifest runner: `go/conformance/harness_test.go` (optional)

Node.js
- handshake: `node/test/integration.test.js`
- auth: implicit via connection
- prepare_bind: `node/test/integration.test.js`
- types_one_way: `node/test/integration.test.js`

Python
- handshake: `python/tests/test_integration.py`
- auth: implicit via connection
- prepare_bind: `python/tests/test_integration.py`
- types_one_way: `python/tests/test_integration.py`

Ruby
- handshake: `ruby/test/test_integration.rb`
- auth: implicit via connection
- prepare_bind: `ruby/test/test_integration.rb`
- types_one_way: `ruby/test/test_integration.rb`

R
- handshake: `r/tests/testthat/test_integration.R`
- auth: implicit via connection
- prepare_bind: `r/tests/testthat/test_integration.R`
- types_one_way: `r/tests/testthat/test_integration.R`

PHP
- handshake: `php/tests/IntegrationTest.php`
- auth: implicit via connection
- prepare_bind: `php/tests/IntegrationTest.php`
- types_one_way: `php/tests/IntegrationTest.php`

Rust
- handshake: `rust/tests/integration_test.rs`
- auth: implicit via connection
- prepare_bind: `rust/tests/integration_test.rs`
- types_one_way: `rust/tests/integration_test.rs`

.NET
- handshake: `dotnet/tests/ScratchBird.Data.Tests/IntegrationTests.cs`
- auth: implicit via connection
- prepare_bind: `dotnet/tests/ScratchBird.Data.Tests/IntegrationTests.cs`
- types_one_way: `dotnet/tests/ScratchBird.Data.Tests/IntegrationTests.cs`

Pascal/Delphi
- handshake: `pascal/tests/IntegrationTest.pas`
- auth: implicit via connection
- prepare_bind: `pascal/tests/IntegrationTest.pas`
- types_one_way: `pascal/tests/IntegrationTest.pas`

JDBC
- handshake: `jdbc/src/test/java/com/scratchbird/jdbc/SBIntegrationTest.java`
- auth: implicit via connection
- prepare_bind: `jdbc/src/test/java/com/scratchbird/jdbc/SBIntegrationTest.java`
- types_one_way: `jdbc/src/test/java/com/scratchbird/jdbc/SBIntegrationTest.java`
