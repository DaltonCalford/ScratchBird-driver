# S6 Driver Gate Results (2026-03-03)

This report aggregates per-lane conformance gate execution evidence for the driver baseline implementation plan.

## Lane Results

| Driver | Gate Command(s) | Result |
|---|---|---|
| JDBC | `./gradlew test --tests com.scratchbird.jdbc.SBSQLParserTest --tests com.scratchbird.jdbc.SBStatementGeneratedKeysTest` | PASS |
| ODBC | `cmake --build /home/dcalford/CliWork/ScratchBird-driver/build --target scratchbird_odbc_tests -j4` + `scratchbird_odbc_tests --gtest_filter='OdbcMetadataShapingTest.*:OdbcCapabilityBrowseTest.BrowseConnect*'` | PASS |
| CPP | `cmake -S . -B build_odbc_gate && cmake --build build_odbc_gate -j4` + `./build_odbc_gate/scratchbird_client_tests --gtest_filter=MetadataSchemaTreeTest.*` | PASS |
| DOTNET | `dotnet test tests/ScratchBird.Data.Tests/ScratchBird.Data.Tests.csproj --filter "FullyQualifiedName~ScratchBirdConnectionMetadataShapingTests|FullyQualifiedName~ScratchBirdConnectionSchemaStatementTests|FullyQualifiedName~ConfigTests.ParseMetadataExpandSchemaParentsAliases"` | PASS |
| GO | `go test . -run 'TestMetadata|TestParseMetadataExpandSchemaParents'` | PASS |
| RUST | `CARGO_TARGET_DIR=/tmp/sb_rust_metadata_target cargo test --test metadata_test` | PASS |
| NODE | `npm run build && node --test test/unit.test.js` | PASS |
| PYTHON | `pytest -q tests/test_metadata_recursive_schema.py tests/test_connection_auth_protocol.py` | PASS |
| PHP | `php tests/metadata_recursive_schema_smoke.php` + `php -l` checks for metadata files | PASS |
| RUBY | `ruby -Itest test/test_metadata_recursive_schema.rb` (+ regression checks: `test_sql.rb`, `test_txn_exec_parity.rb`, `test_conn_auth_protocol.rb`) | PASS |
| PASCAL | `fpc -Mdelphi -Fu./src -FE/tmp/sb_pascal_tests -FU/tmp/sb_pascal_tests ./tests/MetadataRecursiveSchemaTests.pas` + `/tmp/sb_pascal_tests/MetadataRecursiveSchemaTests` | PASS |
| MOJO | `cd ~/mojo-work/sb-mojo && pixi run mojo tests/metadata_recursive_schema.mojo` (+ `txn_exec_parity.mojo`, `integration.mojo`) | FAIL (compile/parse compatibility and module-resolution issues) |
| CLI | `cmake -S tracks/alpha/drivers/cli -B /tmp/sb_cli_s3_build && cmake --build /tmp/sb_cli_s3_build --target sbdriver_txn_exec_tests sbdriver_metadata_shaping_tests -j4` + `/tmp/sb_cli_s3_build/sbdriver_txn_exec_tests` + `/tmp/sb_cli_s3_build/sbdriver_metadata_shaping_tests` | PASS |
| DART | `dart test test/metadata_recursive_schema_test.dart` (+ lane suite subset including config/type/txn parity) | PASS |
| SWIFT | `swift test --build-path /tmp/sb_swift_s3_build --filter MetadataRecursiveSchemaTests` | PASS |
| R | `Rscript -e 'testthat::test_local(filter = "metadata_recursive_schema", reporter = "summary")'` | PASS |

## Integration Gate Summary

- Cross-driver lane gate execution completed for all lanes.
- 15/16 lanes have passing gate commands.
- Exception lane: MOJO (toolchain available via pixi, but current lane tests require syntax/module compatibility fixes before runtime pass).

