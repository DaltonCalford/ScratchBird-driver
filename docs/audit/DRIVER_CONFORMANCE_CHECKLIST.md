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
- handshake: `tracks/alpha/drivers/go/integration_test.go`
- auth: implicit via connection
- prepare_bind: `tracks/alpha/drivers/go/integration_test.go`
- types_one_way: `tracks/alpha/drivers/go/integration_test.go`
- manifest runner: `tracks/alpha/drivers/go/conformance/harness_test.go` (optional)

Node.js
- handshake: `tracks/alpha/drivers/node/test/integration.test.js`
- auth: implicit via connection
- prepare_bind: `tracks/alpha/drivers/node/test/integration.test.js`
- types_one_way: `tracks/alpha/drivers/node/test/integration.test.js`

Python
- handshake: `tracks/alpha/drivers/python/tests/test_integration.py`
- auth: implicit via connection
- prepare_bind: `tracks/alpha/drivers/python/tests/test_integration.py`
- types_one_way: `tracks/alpha/drivers/python/tests/test_integration.py`

Ruby
- handshake: `tracks/alpha/drivers/ruby/test/test_integration.rb`
- auth: implicit via connection
- prepare_bind: `tracks/alpha/drivers/ruby/test/test_integration.rb`
- types_one_way: `tracks/alpha/drivers/ruby/test/test_integration.rb`

R
- handshake: `tracks/beta/drivers/r/tests/testthat/test_integration.R`
- auth: implicit via connection
- prepare_bind: `tracks/beta/drivers/r/tests/testthat/test_integration.R`
- types_one_way: `tracks/beta/drivers/r/tests/testthat/test_integration.R`

PHP
- handshake: `tracks/alpha/drivers/php/tests/IntegrationTest.php`
- auth: implicit via connection
- prepare_bind: `tracks/alpha/drivers/php/tests/IntegrationTest.php`
- types_one_way: `tracks/alpha/drivers/php/tests/IntegrationTest.php`

Rust
- handshake: `tracks/alpha/drivers/rust/tests/integration_test.rs`
- auth: implicit via connection
- prepare_bind: `tracks/alpha/drivers/rust/tests/integration_test.rs`
- types_one_way: `tracks/alpha/drivers/rust/tests/integration_test.rs`

.NET
- handshake: `tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/IntegrationTests.cs`
- auth: implicit via connection
- prepare_bind: `tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/IntegrationTests.cs`
- types_one_way: `tracks/alpha/drivers/dotnet/tests/ScratchBird.Data.Tests/IntegrationTests.cs`

Pascal/Delphi
- handshake: `tracks/alpha/drivers/pascal/tests/IntegrationTest.pas`
- auth: implicit via connection
- prepare_bind: `tracks/alpha/drivers/pascal/tests/IntegrationTest.pas`
- types_one_way: `tracks/alpha/drivers/pascal/tests/IntegrationTest.pas`

JDBC
- handshake: `tracks/alpha/drivers/jdbc/src/test/java/com/scratchbird/jdbc/SBIntegrationTest.java`
- auth: implicit via connection
- prepare_bind: `tracks/alpha/drivers/jdbc/src/test/java/com/scratchbird/jdbc/SBIntegrationTest.java`
- types_one_way: `tracks/alpha/drivers/jdbc/src/test/java/com/scratchbird/jdbc/SBIntegrationTest.java`
