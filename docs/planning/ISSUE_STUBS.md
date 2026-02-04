# Issue Stubs (Generated)

Use these stubs to create tracker issues. Replace `TBD` with real issue IDs in `docs/planning/ISSUE_INDEX.md`.

## 1. Validate `sb_isql` against SBWP v1.1 conformance harness

Checklist: `cli.md`
Priority: P1 (Core)

Description:
Validate `sb_isql` against SBWP v1.1 conformance harness in `cli/sb_isql.cpp`

Files:
- `sb_isql`
- `cli/sb_isql.cpp`

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

Description:
Expand `sb_type` and `sb_value` coverage to full SBWP type matrix in `cpp/include/scratchbird/client/scratchbird_client.h`

Files:
- `sb_type`
- `sb_value`
- `cpp/include/scratchbird/client/scratchbird_client.h`

## 4. Implement encoding/decoding for arrays, composite, range, geometry, vector, inet/cidr/macaddr

Checklist: `cpp.md`
Priority: P1 (Core)

Description:
Implement encoding/decoding for arrays, composite, range, geometry, vector, inet/cidr/macaddr in `cpp/src/`

Files:
- `cpp/src/`

## 5. Expose SET_OPTION and PING helpers and `cpp/src/scratchbird_client_c.cpp`

Checklist: `cpp.md`
Priority: P1 (Core)

Description:
Expose SET_OPTION and PING helpers in `cpp/include/scratchbird/client/scratchbird_client.h` and `cpp/src/scratchbird_client_c.cpp`

Files:
- `cpp/include/scratchbird/client/scratchbird_client.h`
- `cpp/src/scratchbird_client_c.cpp`

## 6. Add sys.* metadata helper queries or API

Checklist: `cpp.md`
Priority: P1 (Core)

Description:
Add sys.* metadata helper queries or API in `cpp/include/scratchbird/client/`

Files:
- `cpp/include/scratchbird/client/`

## 7. Add conformance tests for type mapping and paging

Checklist: `cpp.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for type mapping and paging in `cpp/tests/`

Files:
- `cpp/tests/`

## 8. Enforce TLS required (reject `sslmode=disable`)

Checklist: `dart.md`
Priority: P0 (Blocking)

Description:
Enforce TLS required (reject `sslmode=disable`) in `dart/lib/src/client.dart`

Files:
- `sslmode=disable`
- `dart/lib/src/client.dart`

## 9. Enforce binary-only (reject `binary_transfer=false`) or `dart/lib/src/config.dart`

Checklist: `dart.md`
Priority: P0 (Blocking)

Description:
Enforce binary-only (reject `binary_transfer=false`) in `dart/lib/src/client.dart` or `dart/lib/src/config.dart`

Files:
- `binary_transfer=false`
- `dart/lib/src/client.dart`
- `dart/lib/src/config.dart`

## 10. Reject `compression=zstd` until server support exists

Checklist: `dart.md`
Priority: P0 (Blocking)

Description:
Reject `compression=zstd` until server support exists in `dart/lib/src/client.dart`

Files:
- `compression=zstd`
- `dart/lib/src/client.dart`

## 11. Add array encoding/decoding

Checklist: `dart.md`
Priority: P1 (Core)

Description:
Add array encoding/decoding in `dart/lib/src/types.dart`

Files:
- `dart/lib/src/types.dart`

## 12. Add composite encoding/decoding

Checklist: `dart.md`
Priority: P1 (Core)

Description:
Add composite encoding/decoding in `dart/lib/src/types.dart`

Files:
- `dart/lib/src/types.dart`

## 13. Add vector literal encode/decode

Checklist: `dart.md`
Priority: P1 (Core)

Description:
Add vector literal encode/decode in `dart/lib/src/types.dart`

Files:
- `dart/lib/src/types.dart`

## 14. Add inet/cidr/macaddr encode/decode

Checklist: `dart.md`
Priority: P1 (Core)

Description:
Add inet/cidr/macaddr encode/decode in `dart/lib/src/types.dart`

Files:
- `dart/lib/src/types.dart`

## 15. Add sys.* metadata helpers and export via `dart/lib/scratchbird.dart`

Checklist: `dart.md`
Priority: P1 (Core)

Description:
Add sys.* metadata helpers in `dart/lib/src/metadata.dart` and export via `dart/lib/scratchbird.dart`

Files:
- `dart/lib/src/metadata.dart`
- `dart/lib/scratchbird.dart`

## 16. Add conformance/integration tests

Checklist: `dart.md`
Priority: P2 (Follow-ups)

Description:
Add conformance/integration tests in `dart/test/`

Files:
- `dart/test/`

## 17. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `dotnet.md`
Priority: P1 (Core)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `dotnet/src/ScratchBird.Data/Errors.cs`

Files:
- `dotnet/src/ScratchBird.Data/Errors.cs`

## 18. Add conformance tests for full type matrix

Checklist: `dotnet.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `dotnet/tests/`

Files:
- `dotnet/tests/`

## 19. Enforce TLS required (reject `sslmode=disable`)

Checklist: `elixir.md`
Priority: P0 (Blocking)

Description:
Enforce TLS required (reject `sslmode=disable`) in `elixir/lib/scratchbird/connection.ex`

Files:
- `sslmode=disable`
- `elixir/lib/scratchbird/connection.ex`

## 20. Enforce binary-only (reject `binary_transfer=false`)

Checklist: `elixir.md`
Priority: P0 (Blocking)

Description:
Enforce binary-only (reject `binary_transfer=false`) in `elixir/lib/scratchbird/connection.ex`

Files:
- `binary_transfer=false`
- `elixir/lib/scratchbird/connection.ex`

## 21. Reject `compression=zstd` until server support exists

Checklist: `elixir.md`
Priority: P0 (Blocking)

Description:
Reject `compression=zstd` until server support exists in `elixir/lib/scratchbird/connection.ex`

Files:
- `compression=zstd`
- `elixir/lib/scratchbird/connection.ex`

## 22. Add array encoding/decoding

Checklist: `elixir.md`
Priority: P1 (Core)

Description:
Add array encoding/decoding in `elixir/lib/scratchbird/types.ex`

Files:
- `elixir/lib/scratchbird/types.ex`

## 23. Add composite encoding/decoding

Checklist: `elixir.md`
Priority: P1 (Core)

Description:
Add composite encoding/decoding in `elixir/lib/scratchbird/types.ex`

Files:
- `elixir/lib/scratchbird/types.ex`

## 24. Add vector literal encode/decode

Checklist: `elixir.md`
Priority: P1 (Core)

Description:
Add vector literal encode/decode in `elixir/lib/scratchbird/types.ex`

Files:
- `elixir/lib/scratchbird/types.ex`

## 25. Add inet/cidr/macaddr encode/decode

Checklist: `elixir.md`
Priority: P1 (Core)

Description:
Add inet/cidr/macaddr encode/decode in `elixir/lib/scratchbird/types.ex`

Files:
- `elixir/lib/scratchbird/types.ex`

## 26. Add sys.* metadata helpers and export from `elixir/lib/scratchbird.ex`

Checklist: `elixir.md`
Priority: P1 (Core)

Description:
Add sys.* metadata helpers in `elixir/lib/scratchbird/metadata.ex` and export from `elixir/lib/scratchbird.ex`

Files:
- `elixir/lib/scratchbird/metadata.ex`
- `elixir/lib/scratchbird.ex`

## 27. Add SQLSTATE class-prefix mapping

Checklist: `elixir.md`
Priority: P1 (Core)

Description:
Add SQLSTATE class-prefix mapping in `elixir/lib/scratchbird/errors.ex`

Files:
- `elixir/lib/scratchbird/errors.ex`

## 28. Add conformance/integration tests

Checklist: `elixir.md`
Priority: P2 (Follow-ups)

Description:
Add conformance/integration tests in `elixir/test/`

Files:
- `elixir/test/`

## 29. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `go.md`
Priority: P1 (Core)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `go/errors.go`

Files:
- `go/errors.go`

## 30. Add conformance tests for full type matrix

Checklist: `go.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `go/conformance/`

Files:
- `go/conformance/`

## 31. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping (error mapping)

Checklist: `jdbc.md`
Priority: P1 (Core)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `jdbc/src/main/java/com/scratchbird/jdbc/` (error mapping)

Files:
- `jdbc/src/main/java/com/scratchbird/jdbc/`

## 32. Add conformance tests for full type matrix

Checklist: `jdbc.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `jdbc/src/test/`

Files:
- `jdbc/src/test/`

## 33. Revalidate `scratchbird-feature-support` flags vs JDBC metadata coverage

Checklist: `metabase.md`
Priority: P1 (Core)

Description:
Revalidate `scratchbird-feature-support` flags vs JDBC metadata coverage in `scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`

Files:
- `scratchbird-feature-support`
- `scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`

## 34. Improve type mapping for complex SBWP types

Checklist: `metabase.md`
Priority: P2 (Follow-ups)

Description:
Improve type mapping for complex SBWP types in `scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`

Files:
- `scratchbird-metabase-driver/src/metabase/driver/scratchbird.clj`

## 35. Replace Python bridge with native SBWP client

Checklist: `mojo.md`
Priority: P0 (Blocking)

Description:
Replace Python bridge with native SBWP client in `mojo/src/scratchbird.mojo`

Files:
- `mojo/src/scratchbird.mojo`

## 36. Enforce TLS required and binary-only once native transport exists

Checklist: `mojo.md`
Priority: P0 (Blocking)

Description:
Enforce TLS required and binary-only once native transport exists

## 37. Reject `compression=zstd` until server support exists

Checklist: `mojo.md`
Priority: P0 (Blocking)

Description:
Reject `compression=zstd` until server support exists

Files:
- `compression=zstd`

## 38. Implement SBWP type encoding/decoding wrappers

Checklist: `mojo.md`
Priority: P1 (Core)

Description:
Implement SBWP type encoding/decoding wrappers in `mojo/src/scratchbird.mojo`

Files:
- `mojo/src/scratchbird.mojo`

## 39. Add array, composite, range, geometry, vector, inet/cidr/macaddr support

Checklist: `mojo.md`
Priority: P1 (Core)

Description:
Add array, composite, range, geometry, vector, inet/cidr/macaddr support

## 40. Add sys.* metadata helpers

Checklist: `mojo.md`
Priority: P1 (Core)

Description:
Add sys.* metadata helpers in `mojo/src/scratchbird.mojo`

Files:
- `mojo/src/scratchbird.mojo`

## 41. Add conformance/integration tests

Checklist: `mojo.md`
Priority: P2 (Follow-ups)

Description:
Add conformance/integration tests

## 42. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `node.md`
Priority: P1 (Core)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `node/src/errors.ts`

Files:
- `node/src/errors.ts`

## 43. Add conformance tests for full type matrix

Checklist: `node.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `node/test/`

Files:
- `node/test/`

## 44. Expand type mapping to cover complex SBWP types where applicable

Checklist: `odbc.md`
Priority: P1 (Core)

Description:
Expand type mapping to cover complex SBWP types where applicable in `odbc/src/odbc_client_bridge.cpp`

Files:
- `odbc/src/odbc_client_bridge.cpp`

## 45. Removed fallback metadata queries; use only server-defined `sys.columns` and `sys.index_columns` columns

Checklist: `odbc.md`
Priority: P2 (Follow-ups)

Description:
Removed fallback metadata queries; use only server-defined `sys.columns` and `sys.index_columns` columns in `odbc/src/odbc_handles.cpp`

Files:
- `sys.columns`
- `sys.index_columns`
- `odbc/src/odbc_handles.cpp`

## 46. Add conformance tests for metadata + type coverage

Checklist: `odbc.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for metadata + type coverage in `odbc/tests/`

Files:
- `odbc/tests/`

## 47. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `pascal.md`
Priority: P1 (Core)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `pascal/src/ScratchBird.Errors.pas`

Files:
- `pascal/src/ScratchBird.Errors.pas`

## 48. Add conformance tests for full type matrix

Checklist: `pascal.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `pascal/tests/`

Files:
- `pascal/tests/`

## 49. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `php.md`
Priority: P1 (Core)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `php/src/Errors.php`

Files:
- `php/src/Errors.php`

## 50. Add conformance tests for full type matrix

Checklist: `php.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `php/tests/`

Files:
- `php/tests/`

## 51. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `python.md`
Priority: P1 (Core)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `python/src/scratchbird/connection.py`

Files:
- `python/src/scratchbird/connection.py`

## 52. Add conformance tests for full type matrix

Checklist: `python.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `python/tests/`

Files:
- `python/tests/`

## 53. Add SQLSTATE class-prefix mapping (currently only prefixes message)

Checklist: `r.md`
Priority: P1 (Core)

Description:
Add SQLSTATE class-prefix mapping (currently only prefixes message) in `r/R/client.R`

Files:
- `r/R/client.R`

## 54. Add conformance tests for full type matrix

Checklist: `r.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `r/tests/`

Files:
- `r/tests/`

## 55. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `ruby.md`
Priority: P1 (Core)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `ruby/lib/scratchbird/errors.rb`

Files:
- `ruby/lib/scratchbird/errors.rb`

## 56. Add conformance tests for full type matrix

Checklist: `ruby.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `ruby/test/`

Files:
- `ruby/test/`

## 57. Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping

Checklist: `rust.md`
Priority: P1 (Core)

Description:
Replace SQLSTATE class-prefix mapping with spec-complete SQLSTATE mapping in `rust/src/errors.rs`

Files:
- `rust/src/errors.rs`

## 58. Add conformance tests for full type matrix

Checklist: `rust.md`
Priority: P2 (Follow-ups)

Description:
Add conformance tests for full type matrix in `rust/tests/`

Files:
- `rust/tests/`

## 59. Map column types using `sys.columns.data_type_name` (remove numeric `data_type_id` fallback)

Checklist: `superset.md`
Priority: P1 (Core)

Description:
Map column types using `sys.columns.data_type_name` (remove numeric `data_type_id` fallback) in `scratchbird-superset-driver/scratchbird_superset/dialect.py`

Files:
- `sys.columns.data_type_name`
- `data_type_id`
- `scratchbird-superset-driver/scratchbird_superset/dialect.py`

## 60. Expand type mapping for arrays, ranges, geometry to richer SQLAlchemy types

Checklist: `superset.md`
Priority: P2 (Follow-ups)

Description:
Expand type mapping for arrays, ranges, geometry to richer SQLAlchemy types in `scratchbird-superset-driver/scratchbird_superset/dialect.py`

Files:
- `scratchbird-superset-driver/scratchbird_superset/dialect.py`

## 61. Implement TLS transport

Checklist: `swift.md`
Priority: P0 (Blocking)

Description:
Implement TLS transport in `swift/Sources/ScratchBird/Socket.swift`

Files:
- `swift/Sources/ScratchBird/Socket.swift`

## 62. Enforce binary-only (reject `binary_transfer=false`)

Checklist: `swift.md`
Priority: P0 (Blocking)

Description:
Enforce binary-only (reject `binary_transfer=false`) in `swift/Sources/ScratchBird/Connection.swift`

Files:
- `binary_transfer=false`
- `swift/Sources/ScratchBird/Connection.swift`

## 63. Reject `compression=zstd` until server support exists

Checklist: `swift.md`
Priority: P0 (Blocking)

Description:
Reject `compression=zstd` until server support exists in `swift/Sources/ScratchBird/Connection.swift`

Files:
- `compression=zstd`
- `swift/Sources/ScratchBird/Connection.swift`

## 64. Add array encoding/decoding

Checklist: `swift.md`
Priority: P1 (Core)

Description:
Add array encoding/decoding in `swift/Sources/ScratchBird/Types.swift`

Files:
- `swift/Sources/ScratchBird/Types.swift`

## 65. Add composite encoding/decoding

Checklist: `swift.md`
Priority: P1 (Core)

Description:
Add composite encoding/decoding in `swift/Sources/ScratchBird/Types.swift`

Files:
- `swift/Sources/ScratchBird/Types.swift`

## 66. Add range encoding/decoding

Checklist: `swift.md`
Priority: P1 (Core)

Description:
Add range encoding/decoding in `swift/Sources/ScratchBird/Types.swift`

Files:
- `swift/Sources/ScratchBird/Types.swift`

## 67. Add inet/cidr/macaddr encode/decode

Checklist: `swift.md`
Priority: P1 (Core)

Description:
Add inet/cidr/macaddr encode/decode in `swift/Sources/ScratchBird/Types.swift`

Files:
- `swift/Sources/ScratchBird/Types.swift`

## 68. Add vector literal encode/decode

Checklist: `swift.md`
Priority: P1 (Core)

Description:
Add vector literal encode/decode in `swift/Sources/ScratchBird/Types.swift`

Files:
- `swift/Sources/ScratchBird/Types.swift`

## 69. Add sys.* metadata helpers

Checklist: `swift.md`
Priority: P1 (Core)

Description:
Add sys.* metadata helpers in `swift/Sources/ScratchBird/Metadata.swift`

Files:
- `swift/Sources/ScratchBird/Metadata.swift`

## 70. Add conformance/integration tests

Checklist: `swift.md`
Priority: P2 (Follow-ups)

Description:
Add conformance/integration tests in `swift/Tests/`

Files:
- `swift/Tests/`

