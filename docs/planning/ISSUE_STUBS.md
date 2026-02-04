# Issue Stubs (Generated)

Use these stubs to create tracker issues. Replace `TBD` with real issue IDs in `docs/planning/ISSUE_INDEX.md`.

## 1. Validate `sb_isql` against SBWP v1.1 conformance harness

Checklist: `cli.md`
Priority: P1 (Core)

Description:
Validate `sb_isql` against SBWP v1.1 conformance harness in `tracks/alpha/drivers/cli/sb_isql.cpp`

Files:
- `sb_isql`
- `tracks/alpha/drivers/cli/sb_isql.cpp`

## 2. Validate `sbdriver_conformance` output against `docs/specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md`

Checklist: `cli.md`
Priority: P1 (Core)

Description:
Validate `sbdriver_conformance` output against `docs/specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md`

Files:
- `sbdriver_conformance`
- `docs/specifications/DRIVER_CONFORMANCE_TEST_HARNESS.md`

## 3. Expand `sb_type` and `sb_value` coverage to full SBWP type matrix

Checklist: `cpp.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Expand `sb_type` and `sb_value` coverage to full SBWP type matrix in `tracks/beta/drivers/cpp/include/scratchbird/client/scratchbird_client.h`

Files:
- `sb_type`
- `sb_value`
- `tracks/beta/drivers/cpp/include/scratchbird/client/scratchbird_client.h`

## 4. Implement encoding/decoding for arrays, composite, range, geometry, vector, inet/cidr/macaddr

Checklist: `cpp.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Implement encoding/decoding for arrays, composite, range, geometry, vector, inet/cidr/macaddr in `tracks/beta/drivers/cpp/src/`

Files:
- `tracks/beta/drivers/cpp/src/`

## 5. Expose SET_OPTION and PING helpers and `tracks/beta/drivers/cpp/src/scratchbird_client_c.cpp`

Checklist: `cpp.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Expose SET_OPTION and PING helpers in `tracks/beta/drivers/cpp/include/scratchbird/client/scratchbird_client.h` and `tracks/beta/drivers/cpp/src/scratchbird_client_c.cpp`

Files:
- `tracks/beta/drivers/cpp/include/scratchbird/client/scratchbird_client.h`
- `tracks/beta/drivers/cpp/src/scratchbird_client_c.cpp`

## 6. Add sys.* metadata helper queries or API

Checklist: `cpp.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add sys.* metadata helper queries or API in `tracks/beta/drivers/cpp/include/scratchbird/client/`

Files:
- `tracks/beta/drivers/cpp/include/scratchbird/client/`

## 7. Add conformance tests for type mapping and paging

Checklist: `cpp.md`
Priority: P2 (Follow-ups)
Status: Done (2026-02-04)

Description:
Add conformance tests for type mapping and paging in `tracks/beta/drivers/cpp/tests/`

Files:
- `tracks/beta/drivers/cpp/tests/`

## 8. Enforce TLS required (reject `sslmode=disable`)

Checklist: `dart.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Enforce TLS required (reject `sslmode=disable`) in `tracks/beta/drivers/dart/lib/src/client.dart`

Files:
- `sslmode=disable`
- `tracks/beta/drivers/dart/lib/src/client.dart`

## 9. Enforce binary-only (reject `binary_transfer=false`) or `tracks/beta/drivers/dart/lib/src/config.dart`

Checklist: `dart.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Enforce binary-only (reject `binary_transfer=false`) in `tracks/beta/drivers/dart/lib/src/client.dart` or `tracks/beta/drivers/dart/lib/src/config.dart`

Files:
- `binary_transfer=false`
- `tracks/beta/drivers/dart/lib/src/client.dart`
- `tracks/beta/drivers/dart/lib/src/config.dart`

## 10. Reject `compression=zstd` until server support exists

Checklist: `dart.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Reject `compression=zstd` until server support exists in `tracks/beta/drivers/dart/lib/src/client.dart`

Files:
- `compression=zstd`
- `tracks/beta/drivers/dart/lib/src/client.dart`

## 11. Add array encoding/decoding

Checklist: `dart.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add array encoding/decoding in `tracks/beta/drivers/dart/lib/src/types.dart`

Files:
- `tracks/beta/drivers/dart/lib/src/types.dart`

## 12. Add composite encoding/decoding

Checklist: `dart.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add composite encoding/decoding in `tracks/beta/drivers/dart/lib/src/types.dart`

Files:
- `tracks/beta/drivers/dart/lib/src/types.dart`

## 13. Add vector literal encode/decode

Checklist: `dart.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add vector literal encode/decode in `tracks/beta/drivers/dart/lib/src/types.dart`

Files:
- `tracks/beta/drivers/dart/lib/src/types.dart`

## 14. Add inet/cidr/macaddr encode/decode

Checklist: `dart.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add inet/cidr/macaddr encode/decode in `tracks/beta/drivers/dart/lib/src/types.dart`

Files:
- `tracks/beta/drivers/dart/lib/src/types.dart`

## 15. Add sys.* metadata helpers and export via `tracks/beta/drivers/dart/lib/scratchbird.dart`

Checklist: `dart.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add sys.* metadata helpers in `tracks/beta/drivers/dart/lib/src/metadata.dart` and export via `tracks/beta/drivers/dart/lib/scratchbird.dart`

Files:
- `tracks/beta/drivers/dart/lib/src/metadata.dart`
- `tracks/beta/drivers/dart/lib/scratchbird.dart`

## 16. Add conformance/integration tests

Checklist: `dart.md`
Priority: P2 (Follow-ups)
Status: Done (2026-02-04)

Description:
Add conformance/integration tests in `tracks/beta/drivers/dart/test/`

Files:
- `tracks/beta/drivers/dart/test/`

## 17. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `dotnet.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/dotnet/src/ScratchBird.Data/Errors.cs`

Files:
- `tracks/alpha/drivers/dotnet/src/ScratchBird.Data/Errors.cs`

## 18. Add conformance tests for full type matrix

Checklist: `dotnet.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/alpha/drivers/dotnet/tests/`

Files:
- `tracks/alpha/drivers/dotnet/tests/`

## 19. Enforce TLS required (reject `sslmode=disable`)

Checklist: `elixir.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Enforce TLS required (reject `sslmode=disable`) in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`

Files:
- `sslmode=disable`
- `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`

## 20. Enforce binary-only (reject `binary_transfer=false`)

Checklist: `elixir.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Enforce binary-only (reject `binary_transfer=false`) in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`

Files:
- `binary_transfer=false`
- `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`

## 21. Reject `compression=zstd` until server support exists

Checklist: `elixir.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Reject `compression=zstd` until server support exists in `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`

Files:
- `compression=zstd`
- `tracks/p3/drivers/elixir/lib/scratchbird/connection.ex`

## 22. Add array encoding/decoding

Checklist: `elixir.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add array encoding/decoding in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`

Files:
- `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`

## 23. Add composite encoding/decoding

Checklist: `elixir.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add composite encoding/decoding in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`

Files:
- `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`

## 24. Add vector literal encode/decode

Checklist: `elixir.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add vector literal encode/decode in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`

Files:
- `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`

## 25. Add inet/cidr/macaddr encode/decode

Checklist: `elixir.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add inet/cidr/macaddr encode/decode in `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`

Files:
- `tracks/p3/drivers/elixir/lib/scratchbird/types.ex`

## 26. Add sys.* metadata helpers and export from `tracks/p3/drivers/elixir/lib/scratchbird.ex`

Checklist: `elixir.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add sys.* metadata helpers in `tracks/p3/drivers/elixir/lib/scratchbird/metadata.ex` and export from `tracks/p3/drivers/elixir/lib/scratchbird.ex`

Files:
- `tracks/p3/drivers/elixir/lib/scratchbird/metadata.ex`
- `tracks/p3/drivers/elixir/lib/scratchbird.ex`

## 27. Add SQLSTATE class-prefix mapping

Checklist: `elixir.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add SQLSTATE class-prefix mapping in `tracks/p3/drivers/elixir/lib/scratchbird/errors.ex`

Files:
- `tracks/p3/drivers/elixir/lib/scratchbird/errors.ex`

## 28. Add conformance/integration tests

Checklist: `elixir.md`
Priority: P2 (Follow-ups)
Status: Done (2026-02-04)

Description:
Add conformance/integration tests in `tracks/p3/drivers/elixir/test/`

Files:
- `tracks/p3/drivers/elixir/test/`

## 29. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `go.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/go/errors.go`

Files:
- `tracks/alpha/drivers/go/errors.go`

## 30. Add conformance tests for full type matrix

Checklist: `go.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/alpha/drivers/go/conformance/`

Files:
- `tracks/alpha/drivers/go/conformance/`

## 31. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping (error mapping)

Checklist: `jdbc.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/jdbc/src/main/java/com/scratchbird/jdbc/` (error mapping)

Files:
- `tracks/alpha/drivers/jdbc/src/main/java/com/scratchbird/jdbc/`

## 32. Add conformance tests for full type matrix

Checklist: `jdbc.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/alpha/drivers/jdbc/src/test/`

Files:
- `tracks/alpha/drivers/jdbc/src/test/`

## 33. Revalidate `scratchbird-feature-support` flags vs JDBC metadata coverage

Checklist: `metabase.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Revalidate `scratchbird-feature-support` flags vs JDBC metadata coverage in `tracks/alpha/integrations/scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`

Files:
- `scratchbird-feature-support`
- `tracks/alpha/integrations/scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`

## 34. Improve type mapping for complex SBWP types

Checklist: `metabase.md`
Priority: P2 (Follow-ups)
Status: Done (2026-02-04)

Description:
Improve type mapping for complex SBWP types in `tracks/alpha/integrations/scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`

Files:
- `tracks/alpha/integrations/scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`

## 35. Replace Python bridge with native SBWP client

Checklist: `mojo.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Replace Python bridge with native SBWP client in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`

Files:
- `tracks/alpha/drivers/mojo/src/scratchbird.mojo`

## 36. Enforce TLS required and binary-only once native transport exists

Checklist: `mojo.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Enforce TLS required and binary-only once native transport exists

## 37. Reject `compression=zstd` until server support exists

Checklist: `mojo.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Reject `compression=zstd` until server support exists

Files:
- `compression=zstd`

## 38. Implement SBWP type encoding/decoding wrappers

Checklist: `mojo.md`
Priority: P1 (Core)

Description:
Implement SBWP type encoding/decoding wrappers in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`

Files:
- `tracks/alpha/drivers/mojo/src/scratchbird.mojo`

## 39. Add array, composite, range, geometry, vector, inet/cidr/macaddr support

Checklist: `mojo.md`
Priority: P1 (Core)

Description:
Add array, composite, range, geometry, vector, inet/cidr/macaddr support

## 40. Add sys.* metadata helpers

Checklist: `mojo.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add sys.* metadata helpers in `tracks/alpha/drivers/mojo/src/scratchbird.mojo`

Files:
- `tracks/alpha/drivers/mojo/src/scratchbird.mojo`

## 41. Add conformance/integration tests

Checklist: `mojo.md`
Priority: P2 (Follow-ups)

Description:
Add conformance/integration tests

## 42. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `node.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/node/src/errors.ts`

Files:
- `tracks/alpha/drivers/node/src/errors.ts`

## 43. Add conformance tests for full type matrix

Checklist: `node.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/alpha/drivers/node/test/`

Files:
- `tracks/alpha/drivers/node/test/`

## 44. Expand type mapping to cover complex SBWP types where applicable

Checklist: `odbc.md`
Priority: P1 (Core)

Description:
Expand type mapping to cover complex SBWP types where applicable in `tracks/alpha/drivers/odbc/src/odbc_client_bridge.cpp`

Files:
- `tracks/alpha/drivers/odbc/src/odbc_client_bridge.cpp`

## 45. Removed fallback metadata queries; use only server-defined `sys.columns` and `sys.index_columns` columns

Checklist: `odbc.md`
Priority: P2 (Follow-ups)

Description:
Removed fallback metadata queries; use only server-defined `sys.columns` and `sys.index_columns` columns in `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`

Files:
- `sys.columns`
- `sys.index_columns`
- `tracks/alpha/drivers/odbc/src/odbc_handles.cpp`

## 46. Add conformance tests for metadata + type coverage

Checklist: `odbc.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for metadata + type coverage in `tracks/alpha/drivers/odbc/tests/`

Files:
- `tracks/alpha/drivers/odbc/tests/`

## 47. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `pascal.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/pascal/src/ScratchBird.Errors.pas`

Files:
- `tracks/alpha/drivers/pascal/src/ScratchBird.Errors.pas`

## 48. Add conformance tests for full type matrix

Checklist: `pascal.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/alpha/drivers/pascal/tests/`

Files:
- `tracks/alpha/drivers/pascal/tests/`

## 49. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `php.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/php/src/Errors.php`

Files:
- `tracks/alpha/drivers/php/src/Errors.php`

## 50. Add conformance tests for full type matrix

Checklist: `php.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/alpha/drivers/php/tests/`

Files:
- `tracks/alpha/drivers/php/tests/`

## 51. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `python.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/python/src/scratchbird/connection.py`

Files:
- `tracks/alpha/drivers/python/src/scratchbird/connection.py`

## 52. Add conformance tests for full type matrix

Checklist: `python.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/alpha/drivers/python/tests/`

Files:
- `tracks/alpha/drivers/python/tests/`

## 53. Add SQLSTATE class-prefix mapping (currently only prefixes message)

Checklist: `r.md`
Priority: P1 (Core)

Description:
Add SQLSTATE class-prefix mapping (currently only prefixes message) in `tracks/beta/drivers/r/R/client.R`

Files:
- `tracks/beta/drivers/r/R/client.R`

## 54. Add conformance tests for full type matrix

Checklist: `r.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/beta/drivers/r/tests/`

Files:
- `tracks/beta/drivers/r/tests/`

## 55. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `ruby.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/ruby/lib/scratchbird/errors.rb`

Files:
- `tracks/alpha/drivers/ruby/lib/scratchbird/errors.rb`

## 56. Add conformance tests for full type matrix

Checklist: `ruby.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/alpha/drivers/ruby/test/`

Files:
- `tracks/alpha/drivers/ruby/test/`

## 57. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `rust.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `tracks/alpha/drivers/rust/src/errors.rs`

Files:
- `tracks/alpha/drivers/rust/src/errors.rs`

## 58. Add conformance tests for full type matrix

Checklist: `rust.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `tracks/alpha/drivers/rust/tests/`

Files:
- `tracks/alpha/drivers/rust/tests/`

## 59. Map column types using `sys.columns.data_type_name` (remove numeric `data_type_id` fallback)

Checklist: `superset.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Map column types using `sys.columns.data_type_name` (remove numeric `data_type_id` fallback) in `tracks/beta/integrations/scratchbird-superset-driver/scratchbird_superset/dialect.py`

Files:
- `sys.columns.data_type_name`
- `data_type_id`
- `tracks/beta/integrations/scratchbird-superset-driver/scratchbird_superset/dialect.py`

## 60. Expand type mapping for arrays, ranges, geometry to richer SQLAlchemy types

Checklist: `superset.md`
Priority: P2 (Follow-ups)
Status: Done (2026-02-04)

Description:
Expand type mapping for arrays, ranges, geometry to richer SQLAlchemy types in `tracks/beta/integrations/scratchbird-superset-driver/scratchbird_superset/dialect.py`

Files:
- `tracks/beta/integrations/scratchbird-superset-driver/scratchbird_superset/dialect.py`

## 61. Implement TLS transport

Checklist: `swift.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Implement TLS transport in `tracks/beta/drivers/swift/Sources/ScratchBird/Socket.swift`

Files:
- `tracks/beta/drivers/swift/Sources/ScratchBird/Socket.swift`

## 62. Enforce binary-only (reject `binary_transfer=false`)

Checklist: `swift.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Enforce binary-only (reject `binary_transfer=false`) in `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`

Files:
- `binary_transfer=false`
- `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`

## 63. Reject `compression=zstd` until server support exists

Checklist: `swift.md`
Priority: P0 (Blocking)
Status: Done (2026-02-04)

Description:
Reject `compression=zstd` until server support exists in `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`

Files:
- `compression=zstd`
- `tracks/beta/drivers/swift/Sources/ScratchBird/Connection.swift`

## 64. Add array encoding/decoding

Checklist: `swift.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add array encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

Files:
- `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

## 65. Add composite encoding/decoding

Checklist: `swift.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add composite encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

Files:
- `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

## 66. Add range encoding/decoding

Checklist: `swift.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add range encoding/decoding in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

Files:
- `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

## 67. Add inet/cidr/macaddr encode/decode

Checklist: `swift.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add inet/cidr/macaddr encode/decode in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

Files:
- `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

## 68. Add vector literal encode/decode

Checklist: `swift.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add vector literal encode/decode in `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

Files:
- `tracks/beta/drivers/swift/Sources/ScratchBird/Types.swift`

## 69. Add sys.* metadata helpers

Checklist: `swift.md`
Priority: P1 (Core)
Status: Done (2026-02-04)

Description:
Add sys.* metadata helpers in `tracks/beta/drivers/swift/Sources/ScratchBird/Metadata.swift`

Files:
- `tracks/beta/drivers/swift/Sources/ScratchBird/Metadata.swift`

## 70. Add conformance/integration tests

Checklist: `swift.md`
Priority: P2 (Follow-ups)
Status: Done (2026-02-04)

Description:
Add conformance/integration tests in `tracks/beta/drivers/swift/Tests/`

Files:
- `tracks/beta/drivers/swift/Tests/`
