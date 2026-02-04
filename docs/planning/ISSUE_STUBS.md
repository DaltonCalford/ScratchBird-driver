# Issue Stubs (Generated)

Use these stubs to create tracker issues. Replace `Pending` with real issue IDs in `docs/planning/ISSUE_INDEX.md`.

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

## Deferred Alpha Items (2026-02-04)


## 71. Constraint: Docker images must expose standard ports and support env-based configuration. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`


## 72. Constraint: Non-root container execution should be supported. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`


## 73. Constraint: Volume mounts are required for persistent data. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`


## 74. Test: Validate container starts with read-only root filesystem. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`


## 75. Test: Confirm upgrade path via image tag changes. (Sources: `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/docker/SPECIFICATION.md`


## 76. Constraint: Prometheus scrapes HTTP endpoints (`/metrics`) and expects stable label sets. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `/metrics`
- `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`


## 77. Constraint: Database integration typically relies on exporters; the driver should not require interactive auth. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`


## 78. Constraint: Metrics must be safe for high-frequency scraping. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`


## 79. Test: Validate scrape performance at 15s intervals with minimal allocation. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`


## 80. Test: Ensure metrics include connection pool, query latency, and error counts. (Sources: `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/prometheus/SPECIFICATION.md`


## 81. Constraint: Azure deployments commonly use VNet integration and NSGs for port access. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`


## 82. Constraint: TLS certificates must be compatible with Azure Load Balancers and App Gateways. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`


## 83. Constraint: Managed service deployments should support Azure backup/restore patterns. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`


## 84. Test: Validate connectivity through Azure App Gateway. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`


## 85. Test: Confirm backup/restore procedures. (Sources: `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/azure/SPECIFICATION.md`


## 86. Constraint: Terraform modules should expose variables for ports, storage, and credentials. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`


## 87. Constraint: State changes must be idempotent across applies. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`


## 88. Constraint: Outputs should include connection strings for downstream tooling. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`


## 89. Test: Validate plan/apply on clean and existing environments. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`


## 90. Test: Confirm destroy cleans up all resources. (Sources: `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/terraform/SPECIFICATION.md`


## 91. Constraint: AWS deployments typically use VPC networking, security groups, and IAM roles. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`


## 92. Constraint: Managed deployments should align with RDS-style parameter groups and backups. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`


## 93. Constraint: TLS certificates must be compatible with AWS load balancers. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`


## 94. Test: Validate connectivity through cloud load balancers. (Sources: `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`, `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/aws/SPECIFICATION.md`
- `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`


## 95. Constraint: Kubernetes deployments require ConfigMaps and Secrets for configuration. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`


## 96. Constraint: StatefulSets with persistent volumes are required for durable storage. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`


## 97. Constraint: Readiness and liveness probes must be supported. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`


## 98. Test: Validate rolling upgrade with zero data loss. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`


## 99. Test: Confirm liveness probes detect hung connections. (Sources: `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/kubernetes/SPECIFICATION.md`


## 100. Constraint: GCP deployments use service accounts and firewall rules for connectivity. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`


## 101. Constraint: Cloud SQL-style deployments require TLS and IAM-aware connection policies. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`


## 102. Constraint: Health checks must be compatible with Google Load Balancers. (Sources: `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`)

Checklist: `cli.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cli.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/cloud/gcp/SPECIFICATION.md`


## 103. Constraint: ADO.NET patterns rely on DbConnection, DbCommand, DbDataReader. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`


## 104. Constraint: Providers should support DbProviderFactory usage. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`


## 105. Test: Validate DbDataReader schema metadata. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`


## 106. Test: Confirm DbException SQLSTATE mapping. (Sources: `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/dotnet/SPECIFICATION.md`


## 107. Constraint: EF Core uses LINQ and database providers to translate queries. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`


## 108. Constraint: Provider versions must align with EF Core major versions. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`


## 109. Test: Validate LINQ translation for common filters. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`


## 110. Test: Verify provider version compatibility and migrations. (Sources: `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/entity-framework-core/SPECIFICATION.md`


## 111. Constraint: Dapper uses extension methods like `Query`/`QueryAsync` and `Execute`/`ExecuteAsync` on IDbConnection. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`


## 112. Constraint: Drivers must implement `IDbConnection`, `IDbCommand`, and `IDataReader` correctly for row streaming. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`


## 113. Constraint: Ensure parameter binding supports anonymous objects and `DynamicParameters`. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`


## 114. Test: Validate Dapper multi-mapping (`splitOn`) with joined queries. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`


## 115. Test: Ensure `QueryMultiple` works with multiple result sets. (Sources: `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`)

Checklist: `dotnet.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/dotnet.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/dapper/SPECIFICATION.md`


## 116. Constraint: QueryRow errors are deferred to Scan; no rows returns ErrNoRows. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)

Checklist: `go.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/go.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`


## 117. Constraint: Context-aware methods required for cancellation. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)

Checklist: `go.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/go.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`


## 118. Test: Verify ErrNoRows behavior. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)

Checklist: `go.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/go.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`


## 119. Test: Validate context cancellation. (Sources: `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`)

Checklist: `go.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/go.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/golang/SPECIFICATION.md`


## 120. Constraint: Mattermost uses PostgreSQL for production deployments. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)

Checklist: `go.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/go.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`


## 121. Constraint: DB connection config is in `config.json` with DSN-like fields. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)

Checklist: `go.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/go.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`


## 122. Constraint: Online migrations are common during upgrades. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)

Checklist: `go.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/go.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`


## 123. Test: Validate Mattermost startup migrations complete. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)

Checklist: `go.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/go.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`


## 124. Test: Confirm message, channel, and user CRUD flows. (Sources: `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`)

Checklist: `go.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/go.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/mattermost/SPECIFICATION.md`


## 125. Constraint: DatabaseMetaData.getTables/getColumns return standard ResultSet columns. (Sources: `docs/specifications/integrations/drivers/java/SPECIFICATION.md`, `docs/specifications/integrations/drivers/jdbc/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/java/SPECIFICATION.md`
- `docs/specifications/integrations/drivers/jdbc/SPECIFICATION.md`


## 126. Constraint: getTableTypes should list TABLE/VIEW types. (Sources: `docs/specifications/integrations/drivers/java/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/java/SPECIFICATION.md`


## 127. Test: Validate JDBC metadata column ordering and presence. (Sources: `docs/specifications/integrations/drivers/java/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/java/SPECIFICATION.md`


## 128. Test: Ensure SQLSTATE present on SQLException. (Sources: `docs/specifications/integrations/drivers/java/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/java/SPECIFICATION.md`


## 129. Constraint: getSchemas and getTableTypes should return ordered results. (Sources: `docs/specifications/integrations/drivers/jdbc/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/jdbc/SPECIFICATION.md`


## 130. Test: Validate metadata result sets (tables/columns) and SQLSTATE. (Sources: `docs/specifications/integrations/drivers/jdbc/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/jdbc/SPECIFICATION.md`


## 131. Constraint: DBeaver relies on JDBC drivers and expects a JDBC URL for connections. (Sources: `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`


## 132. Constraint: Driver registration and classpath loading must work with custom driver jars. (Sources: `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`


## 133. Constraint: Metadata queries must be efficient to avoid UI timeouts. (Sources: `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`


## 134. Test: Validate schema browser loads tables, columns, and indexes. (Sources: `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`


## 135. Test: Confirm DBeaver can generate and execute `SELECT` previews. (Sources: `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/dbeaver/SPECIFICATION.md`


## 136. Constraint: pgAdmin expects server registration fields (host, port, maintenance DB, user). (Sources: `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`


## 137. Constraint: Introspection queries should be fast to populate the tree view. (Sources: `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`


## 138. Constraint: SSL modes must be supported for secure connections. (Sources: `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`


## 139. Test: Validate schema tree expansion for tables, indexes, and functions. (Sources: `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`


## 140. Test: Confirm query tool can run parameterized statements. (Sources: `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/pgadmin/SPECIFICATION.md`


## 141. Constraint: Hibernate/JPA expects entity mappings via @Entity and @Table, with @Id for primary keys. (Sources: `docs/specifications/integrations/orm/hibernate-jpa/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/hibernate-jpa/SPECIFICATION.md`


## 142. Constraint: Schema and table naming must align with annotations. (Sources: `docs/specifications/integrations/orm/hibernate-jpa/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/hibernate-jpa/SPECIFICATION.md`


## 143. Test: Validate schema generation via annotations. (Sources: `docs/specifications/integrations/orm/hibernate-jpa/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/hibernate-jpa/SPECIFICATION.md`


## 144. Test: Confirm identifier mapping and primary key handling. (Sources: `docs/specifications/integrations/orm/hibernate-jpa/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/hibernate-jpa/SPECIFICATION.md`


## 145. Constraint: Spark JDBC data sources require a JDBC URL, table or query, and driver class. (Sources: `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`


## 146. Constraint: Partitioning options should be supported for parallel read. (Sources: `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`


## 147. Constraint: Large writes should use batch inserts and prepared statements. (Sources: `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`


## 148. Test: Validate Spark parallel read with partition column + bounds. (Sources: `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`


## 149. Test: Confirm DataFrame writes via JDBC with batch size tuning. (Sources: `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/spark/SPECIFICATION.md`


## 150. Constraint: Kafka Connect JDBC sink uses connector configs like `connection.url` and `table.name.format`. (Sources: `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`


## 151. Constraint: The driver must support auto-commit behavior expected by the sink. (Sources: `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`


## 152. Constraint: Batch inserts and retries must be stable under load. (Sources: `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`


## 153. Test: Validate sink retries on transient errors. (Sources: `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`


## 154. Test: Confirm schema evolution for added columns. (Sources: `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/kafka/SPECIFICATION.md`


## 155. Constraint: Flink JDBC connector requires JDBC URL, driver class, and table schema mapping. (Sources: `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`


## 156. Constraint: Upserts and batch modes should be supported for sinks. (Sources: `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`


## 157. Constraint: Exactly-once semantics depend on transaction and checkpoint support. (Sources: `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`


## 158. Test: Validate Flink sink upserts under checkpointing. (Sources: `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`


## 159. Test: Confirm JDBC source reads with projection and filters. (Sources: `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/flink/SPECIFICATION.md`


## 160. Constraint: Grafana SQL data sources expect query macros and time-series formatting. (Sources: `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`


## 161. Constraint: The driver must return correct time column types and ordering. (Sources: `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`


## 162. Constraint: Connection pooling and query timeouts should be configurable. (Sources: `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`


## 163. Test: Validate time-series queries return consistent time/value columns. (Sources: `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`


## 164. Test: Confirm dashboard refreshes do not leak connections. (Sources: `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/grafana/SPECIFICATION.md`


## 165. Constraint: DataGrip uses JDBC drivers and requires driver JARs to be configured per data source. (Sources: `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`


## 166. Constraint: It expects DatabaseMetaData compatibility for schemas, tables, and columns. (Sources: `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`


## 167. Constraint: SQL dialect quirks must be declared to avoid incorrect SQL generation. (Sources: `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`


## 168. Test: Validate database introspection for schemas and routines. (Sources: `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`


## 169. Test: Confirm parameterized query execution in the query console. (Sources: `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/datagrip/SPECIFICATION.md`


## 170. Constraint: Gremlin uses traversal steps (`g.V()`, `has`, `out`, `values`) and expects streaming results. (Sources: `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`


## 171. Constraint: Parameterized bindings are common in Gremlin to avoid string interpolation. (Sources: `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`


## 172. Constraint: Result types include vertices, edges, and property maps. (Sources: `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`


## 173. Test: Validate traversal step ordering and pagination semantics. (Sources: `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`


## 174. Test: Ensure vertex/edge property maps are decoded consistently. (Sources: `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/gremlin-tinkerpop/SPECIFICATION.md`


## 175. Constraint: Cypher is a property-graph query language using `MATCH`, `WHERE`, and `RETURN` clauses. (Sources: `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`


## 176. Constraint: Parameters are referenced with `$name` and are expected to support list/array binding. (Sources: `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`


## 177. Constraint: Result sets must preserve graph element structure (nodes, relationships, paths). (Sources: `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`


## 178. Test: Validate parameter binding for lists and nested maps. (Sources: `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`


## 179. Test: Ensure path result shapes are preserved in metadata helpers. (Sources: `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/cypher-opencypher/SPECIFICATION.md`


## 180. Constraint: Talend JDBC components (tJDBCConnection, tJDBCInput, tJDBCOutput) expect standard JDBC metadata. (Sources: `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`


## 181. Constraint: Batch size and commit intervals should be configurable. (Sources: `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`


## 182. Constraint: Driver class loading must work in Talend Studio and runtime. (Sources: `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`


## 183. Test: Validate Talend job execution with input/output components. (Sources: `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`


## 184. Test: Confirm batch inserts use prepared statements. (Sources: `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/talend/SPECIFICATION.md`


## 185. Constraint: Informatica PowerCenter supports JDBC for relational sources/targets. (Sources: `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`


## 186. Constraint: Driver class loading must be compatible with PowerCenter runtime. (Sources: `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`


## 187. Constraint: Large batch loads require stable transaction behavior. (Sources: `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`


## 188. Test: Validate PowerCenter session runs with source/target mappings. (Sources: `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`


## 189. Test: Confirm error row handling and retry behavior. (Sources: `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/informatica/SPECIFICATION.md`


## 190. Constraint: HBase SQL access commonly uses Apache Phoenix with JDBC connectivity. (Sources: `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`


## 191. Constraint: The driver must handle Phoenix metadata queries and schema discovery. (Sources: `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`


## 192. Constraint: Upserts and bulk loads require batch-friendly behavior. (Sources: `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`


## 193. Test: Validate Phoenix JDBC metadata reads. (Sources: `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`


## 194. Test: Confirm batch upsert performance with large datasets. (Sources: `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hbase/SPECIFICATION.md`


## 195. Constraint: Hive JDBC storage handlers require JDBC URL and driver class configuration. (Sources: `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`


## 196. Constraint: Hive expects column types to map to SQL types for external tables. (Sources: `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`


## 197. Constraint: Queries should support predicate pushdown where possible. (Sources: `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`


## 198. Test: Validate Hive external table read/write against ScratchBird. (Sources: `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`


## 199. Test: Confirm predicate pushdown reduces row counts. (Sources: `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-hive/SPECIFICATION.md`


## 200. Constraint: Pentaho Data Integration uses JDBC for database steps and requires driver JARs. (Sources: `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`


## 201. Constraint: Metadata queries must be fast for schema browsers. (Sources: `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`


## 202. Constraint: Batch insert steps should use prepared statements. (Sources: `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`


## 203. Test: Validate PDI transformations with Table Input/Output steps. (Sources: `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`


## 204. Test: Confirm metadata browsing for tables and columns. (Sources: `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/pentaho/SPECIFICATION.md`


## 205. Constraint: Pig DBStorage supports storing data to JDBC targets and requires driver jars. (Sources: `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`


## 206. Constraint: Schema mapping must preserve column ordering and nullability. (Sources: `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`


## 207. Constraint: Large batch writes should be chunked to avoid memory spikes. (Sources: `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`


## 208. Test: Validate DBStorage write path with large datasets. (Sources: `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`


## 209. Test: Confirm NULL handling for optional fields. (Sources: `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`)

Checklist: `jdbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/jdbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/bigdata/hadoop-pig/SPECIFICATION.md`


## 210. Constraint: Parameterized queries use positional placeholders and value arrays. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`


## 211. Constraint: Prepared statements are often represented by named query configs. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`


## 212. Test: Validate parameter binding conversion rules for arrays and objects. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`


## 213. Test: Confirm prepared statement name reuse behavior. (Sources: `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/nodejs-typescript/SPECIFICATION.md`


## 214. Constraint: Sequelize requires explicit DataTypes for model attributes. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`


## 215. Constraint: DataTypes support varies by dialect; JSON/JSONB have differing support. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`


## 216. Test: Validate DataTypes mapping for JSON/JSONB and string types. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`


## 217. Test: Verify nullability defaults. (Sources: `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/sequelize/SPECIFICATION.md`


## 218. Constraint: Prisma expects a `datasource` and `generator` in `schema.prisma` with a connection URL. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`


## 219. Constraint: Support introspection flows (similar to `prisma db pull`) and migrations (similar to `prisma migrate`). (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`


## 220. Constraint: Ensure scalar types map cleanly to Prisma field types and `@db` native types. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`


## 221. Test: Validate introspection against a schema with enums, arrays, and JSON. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`


## 222. Test: Ensure Prisma Client queries return correct nullability and enum mappings. (Sources: `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/prisma/SPECIFICATION.md`


## 223. Constraint: Support TypeORM `DataSource` configuration and `DataSourceOptions` fields (host, port, database, username, password, ssl). (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`


## 224. Constraint: Ensure metadata helpers provide table/column info for entity synchronization. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`


## 225. Constraint: Avoid relying on TypeORM `synchronize` for production migrations. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`


## 226. Test: Validate entity metadata discovery for `@Entity` with custom schema. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`


## 227. Test: Verify parameterized queries use positional `$1` or named bindings as expected by the driver. (Sources: `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`)

Checklist: `node.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/node.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/typeorm/SPECIFICATION.md`


## 228. Constraint: SQLColumns must return a column list result set and includes ORDINAL_POSITION. (Sources: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`


## 229. Constraint: Result set metadata is retrieved via SQLNumResultCols and SQLDescribeCol/SQLColAttribute. (Sources: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`


## 230. Test: Validate SQLColumns result set columns (ORDINAL_POSITION, TYPE_NAME, etc.). (Sources: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`


## 231. Test: Validate SQLDescribeCol and SQLNumResultCols behavior. (Sources: `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/odbc/SPECIFICATION.md`


## 232. Constraint: Qlik Sense uses ODBC connectors and expects DSN-based configuration. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`


## 233. Constraint: Metadata queries must be performant for script reloads. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`


## 234. Constraint: Unicode handling must preserve UTF-8 text. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`


## 235. Test: Validate Qlik load script `SELECT` executions. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`


## 236. Test: Confirm reloads handle large tables with paging. (Sources: `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/qlik/SPECIFICATION.md`


## 237. Constraint: Excel uses ODBC data sources and expects DSN configuration via the OS ODBC manager. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`


## 238. Constraint: The driver must expose stable column types for import. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`


## 239. Constraint: Result sets should avoid server-side cursor timeouts. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`


## 240. Test: Validate Excel data import and refresh workflows. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`


## 241. Test: Confirm wide tables and large row counts import correctly. (Sources: `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/excel-odbc/SPECIFICATION.md`


## 242. Constraint: Tableau uses ODBC or JDBC drivers depending on the connector. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`


## 243. Constraint: The driver must expose accurate metadata for Tableau's data model. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`


## 244. Constraint: Large result sets must support paging and cancellation. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`


## 245. Test: Validate Tableau can publish and refresh extracts. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`


## 246. Test: Confirm custom SQL uses parameter binding without errors. (Sources: `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/tableau/SPECIFICATION.md`


## 247. Constraint: Power BI connects via ODBC data sources for custom databases. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`


## 248. Constraint: The driver must expose schema metadata and stable column types. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`


## 249. Constraint: Query folding should be supported where possible. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`


## 250. Test: Validate Power BI can import and refresh datasets. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`


## 251. Test: Confirm DirectQuery mode works with paging and timeouts. (Sources: `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/power-bi/SPECIFICATION.md`


## 252. Constraint: MySQL Workbench migrations use ODBC drivers for source/target connectivity. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`


## 253. Constraint: Metadata discovery must support `SQLTables`, `SQLColumns`, and `SQLPrimaryKeys` equivalents. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`


## 254. Constraint: The driver must tolerate long-running introspection queries. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`


## 255. Test: Validate Workbench migration wizard completes schema introspection. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`


## 256. Test: Confirm data copy works for large tables with paging. (Sources: `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/mysql-workbench/SPECIFICATION.md`


## 257. Constraint: GeoServer PostGIS datastore expects host, port, database, schema, and credentials. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`


## 258. Constraint: Geometry columns must expose spatial reference metadata. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`


## 259. Constraint: Large feature layers should be streamed with paging. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`


## 260. Test: Validate datastore creation and layer publishing. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`


## 261. Test: Confirm WMS/WFS requests return expected features. (Sources: `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/geoserver/SPECIFICATION.md`


## 262. Constraint: QGIS connects to PostGIS via the Data Source Manager and expects spatial metadata tables. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`


## 263. Constraint: Geometry column and SRID metadata must be consistent. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`


## 264. Constraint: Large spatial datasets require cursor-based fetching. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`


## 265. Test: Validate adding a PostGIS layer and rendering features. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`


## 266. Test: Confirm spatial indexes are recognized. (Sources: `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`)

Checklist: `odbc.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/odbc.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/qgis/SPECIFICATION.md`


## 267. Constraint: SQLDB uses TSQLConnector + TSQLTransaction + TSQLQuery flow. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)

Checklist: `pascal.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/pascal.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`


## 268. Constraint: ConnectorType selects backend driver at runtime. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)

Checklist: `pascal.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/pascal.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`


## 269. Test: Validate transaction behavior via TSQLTransaction. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)

Checklist: `pascal.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/pascal.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`


## 270. Test: Confirm schema retrieval APIs (SQLDB) return expected shapes. (Sources: `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`)

Checklist: `pascal.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/pascal.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/pascal-delphi/SPECIFICATION.md`


## 271. Constraint: PDO errorInfo arrays include SQLSTATE as element 0. (Sources: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/php/SPECIFICATION.md`


## 272. Constraint: Statement errorInfo is separate from connection errorInfo. (Sources: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/php/SPECIFICATION.md`


## 273. Test: Validate PDO::errorInfo and PDOStatement::errorInfo SQLSTATE values. (Sources: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/php/SPECIFICATION.md`


## 274. Test: Verify fetch modes and error mode behavior. (Sources: `docs/specifications/integrations/drivers/php/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/php/SPECIFICATION.md`


## 275. Constraint: Magento stores DB configuration in `app/etc/env.php` and expects MySQL-compatible behavior. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `app/etc/env.php`
- `docs/specifications/integrations/apps/magento/SPECIFICATION.md`


## 276. Constraint: Large catalog schemas require long-running migrations and indexed queries. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/magento/SPECIFICATION.md`


## 277. Constraint: UTF-8 and JSON column types must be stable. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/magento/SPECIFICATION.md`


## 278. Test: Validate Magento setup:upgrade completes. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/magento/SPECIFICATION.md`


## 279. Test: Confirm catalog search and checkout workflows. (Sources: `docs/specifications/integrations/apps/magento/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/magento/SPECIFICATION.md`


## 280. Constraint: WordPress expects MySQL/MariaDB-compatible behavior and config in `wp-config.php`. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `wp-config.php`
- `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`


## 281. Constraint: PHP extensions must provide `mysqli`/PDO-style behavior. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`


## 282. Constraint: Collation and charset must be stable for UTF-8 content. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`


## 283. Test: Validate WordPress install and admin login with ScratchBird. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`


## 284. Test: Confirm basic CRUD for posts, users, and taxonomy. (Sources: `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/wordpress/SPECIFICATION.md`


## 285. Constraint: WooCommerce relies on WordPress database behavior and uses the same `wp-config.php` settings. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `wp-config.php`
- `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`


## 286. Constraint: High-concurrency order updates require stable transactions and row-level locking. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`


## 287. Constraint: UTF-8 and JSON metadata must be preserved. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`


## 288. Test: Validate WooCommerce install and product CRUD. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`


## 289. Test: Confirm order creation, payment, and refund flows. (Sources: `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/woocommerce/SPECIFICATION.md`


## 290. Constraint: Laravel uses `config/database.php` and `.env` variables for connection configuration. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `config/database.php`
- `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`


## 291. Constraint: Eloquent expects PDO-based drivers and supports prepared statements by default. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`


## 292. Constraint: Ensure migration commands (`php artisan migrate`) and schema builder operations are supported. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`


## 293. Test: Validate schema builder support for indexes and foreign keys. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`


## 294. Test: Confirm Eloquent casts (date, json, array) match ScratchBird types. (Sources: `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/laravel-eloquent/SPECIFICATION.md`


## 295. Constraint: Joomla stores DB config in `configuration.php` and expects a PDO or MySQLi-style driver. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `configuration.php`
- `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`


## 296. Constraint: Table prefixes and schema initialization must be supported. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`


## 297. Constraint: UTF-8 charset support is required for multilingual content. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`


## 298. Test: Validate Joomla installation and administrator login. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`


## 299. Test: Confirm extension install and upgrade path. (Sources: `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/joomla/SPECIFICATION.md`


## 300. Constraint: Drupal uses `settings.php` and a `databases` array for connection configuration. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `settings.php`
- `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`


## 301. Constraint: PDO support is required for database backends. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`


## 302. Constraint: Schema management relies on Drupal's database API. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`


## 303. Test: Validate Drupal installation and module enablement. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`


## 304. Test: Confirm `drush sql:query` runs with parameters. (Sources: `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`)

Checklist: `php.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/php.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/drupal/SPECIFICATION.md`


## 305. Constraint: PEP 249 defines standard exceptions and `cursor.description` structure. (Sources: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/python/SPECIFICATION.md`


## 306. Constraint: Autocommit should default off; rollback/commit must be exposed. (Sources: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/python/SPECIFICATION.md`


## 307. Test: Validate PEP 249 compliance (apilevel, threadsafety, paramstyle). (Sources: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/python/SPECIFICATION.md`


## 308. Test: Confirm SQLSTATE mapping and error class raising. (Sources: `docs/specifications/integrations/drivers/python/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/python/SPECIFICATION.md`


## 309. Constraint: SQLAlchemy Inspector.get_columns returns dicts with keys like name, type, nullable, default, and autoincrement. (Sources: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`


## 310. Constraint: Dialect reflection must support schema-qualified inspection. (Sources: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`


## 311. Test: Validate reflection metadata keys (name/type/nullable/default). (Sources: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`


## 312. Test: Verify schema-qualified inspection. (Sources: `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/sqlalchemy/SPECIFICATION.md`


## 313. Constraint: LangChain SQL integrations expect SQLAlchemy-style connection URIs. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`


## 314. Constraint: Query results are consumed by chains that expect consistent column naming. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`


## 315. Constraint: Parameter binding must be compatible with SQLAlchemy engine conventions. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`


## 316. Test: Validate schema introspection and sample query execution. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`


## 317. Test: Confirm long-running queries can be cancelled by the chain. (Sources: `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/langchain/SPECIFICATION.md`


## 318. Constraint: Vector APIs expect fixed-dimension vector columns and similarity operators. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`


## 319. Constraint: Index choices (HNSW/IVF) can affect performance and accuracy tradeoffs. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`


## 320. Constraint: Distance functions must be deterministic and numeric-safe. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`


## 321. Test: Validate vector insert/update and top-k similarity queries. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`


## 322. Test: Confirm index build time and recall thresholds. (Sources: `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/vector-apis/SPECIFICATION.md`


## 323. Constraint: Haystack document stores expect consistent schema and efficient filter predicates. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`


## 324. Constraint: SQL-backed document stores require parameterized queries and transaction safety. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`


## 325. Constraint: Embedding/vector fields must preserve dimensionality and order. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`


## 326. Test: Validate insert/update/delete for documents with metadata filters. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`


## 327. Test: Confirm vector similarity queries return stable ordering. (Sources: `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/ai/haystack/SPECIFICATION.md`


## 328. Constraint: Django uses `DATABASES` settings for connection configuration. (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`


## 329. Constraint: Migrations are driven by `manage.py migrate`, and schema introspection expects backend features. (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`


## 330. Constraint: The backend adapter must implement Django Database Backend APIs (operations, features, introspection). (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`


## 331. Test: Validate `inspectdb` output matches metadata contract. (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`


## 332. Test: Confirm Django migration operations for indexes and constraints. (Sources: `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/django-orm/SPECIFICATION.md`


## 333. Constraint: Odoo requires PostgreSQL and manages databases via a dedicated DB user. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`


## 334. Constraint: Connection configuration is typically via `odoo.conf`. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`


## 335. Constraint: Odoo uses large schemas and relies on sequences and constraints. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`


## 336. Test: Validate Odoo database creation and module installation. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`


## 337. Test: Confirm ORM migrations on upgrade. (Sources: `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`)

Checklist: `python.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/python.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/apps/odoo/SPECIFICATION.md`


## 338. Constraint: Conform to Ruby DBI expectations for prepared statements and fetch loops. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`


## 339. Constraint: Ensure exceptions expose SQLSTATE and map to DBI error subclasses. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`


## 340. Constraint: Use UTF-8 encoding for all textual fields. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`


## 341. Test: Validate `DBI::StatementHandle#fetch` and `#finish` behavior under errors. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`


## 342. Test: Confirm `DBI::Database#ping` returns appropriate errors on dropped connections. (Sources: `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/ruby/SPECIFICATION.md`


## 343. Constraint: Rails uses `config/database.yml` for connection configuration and `ActiveRecord::Base.establish_connection` semantics. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `config/database.yml`
- `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`


## 344. Constraint: Migrations must work via `rails db:migrate` and schema dumps must be stable. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`


## 345. Constraint: Adapter must implement the ActiveRecord adapter interface (quoting, schema, type map). (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`


## 346. Test: Validate schema dumping and reload (`schema.rb`) for all core types. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `schema.rb`
- `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`


## 347. Test: Confirm `rails db:migrate` applies and rolls back without metadata drift. (Sources: `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`)

Checklist: `ruby.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/ruby.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/orm/rails-activerecord/SPECIFICATION.md`


## 348. Constraint: Use async-first APIs compatible with Tokio and futures. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)

Checklist: `rust.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/rust.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`


## 349. Constraint: Provide pool configuration for max connections, timeouts, and idle cleanup. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)

Checklist: `rust.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/rust.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`


## 350. Constraint: Support typed row mapping akin to `query_as` conventions. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)

Checklist: `rust.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/rust.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`


## 351. Test: Verify pool reconnects after transient network failures. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)

Checklist: `rust.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/rust.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`


## 352. Test: Ensure error types include SQLSTATE and implement `std::error::Error`. (Sources: `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`)

Checklist: `rust.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/rust.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/rust/SPECIFICATION.md`


## 353. Constraint: Metabase connects via JDBC drivers and expects a driver JAR registered with Metabase. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)

Checklist: `metabase.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/metabase.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`


## 354. Constraint: Metadata APIs must return stable results for schema sync. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)

Checklist: `metabase.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/metabase.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`


## 355. Constraint: SQL dialect hints are required for Metabase query generation. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)

Checklist: `metabase.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/metabase.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`


## 356. Test: Validate Metabase schema sync and field fingerprinting. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)

Checklist: `metabase.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/metabase.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`


## 357. Test: Confirm native query mode executes parameterized SQL. (Sources: `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`)

Checklist: `metabase.md`
Priority: Deferred (Alpha)

Description:
Deferred checklist item from `docs/planning/driver-checklists/metabase.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/tools/metabase/SPECIFICATION.md`

## Deferred Beta/P3 Items (2026-02-04)

## 358. Constraint: Provide a stable C API façade for language bindings where ABI stability is required. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)

Checklist: `cpp.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cpp.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`

## 359. Constraint: Support both static and shared builds with explicit linkage flags. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)

Checklist: `cpp.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cpp.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`

## 360. Constraint: Document ownership of buffers returned to callers. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)

Checklist: `cpp.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cpp.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`

## 361. Test: Verify both static and shared builds link successfully. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)

Checklist: `cpp.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cpp.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`

## 362. Test: Validate row buffers remain valid until the next fetch call. (Sources: `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`)

Checklist: `cpp.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/cpp.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/cpp/SPECIFICATION.md`

## 363. Add SQLSTATE class-prefix mapping (currently only prefixes message) in `tracks/beta/drivers/r/R/client.R`.

Checklist: `r.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/r.md` for later integration/testing work.

Files:
- `tracks/beta/drivers/r/R/client.R`

## 364. Add conformance tests for full type matrix in `tracks/beta/drivers/r/tests/`.

Checklist: `r.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/r.md` for later integration/testing work.

Files:
- `tracks/beta/drivers/r/tests/`

## 365. Constraint: Conform to R DBI generics and return data frames with stable column classes. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)

Checklist: `r.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/r.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/r/SPECIFICATION.md`

## 366. Constraint: Support `dbListTables` and `dbColumnInfo` for metadata introspection. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)

Checklist: `r.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/r.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/r/SPECIFICATION.md`

## 367. Constraint: Treat `NA` and `NULL` per DBI expectations. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)

Checklist: `r.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/r.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/r/SPECIFICATION.md`

## 368. Test: Validate `dbGetQuery` returns consistent `data.frame` column types. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)

Checklist: `r.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/r.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/r/SPECIFICATION.md`

## 369. Test: Ensure `dbBind` supports positional and named parameters. (Sources: `docs/specifications/integrations/drivers/r/SPECIFICATION.md`)

Checklist: `r.md`
Priority: Deferred (Beta/P3)

Description:
Deferred checklist item from `docs/planning/driver-checklists/r.md` for later integration/testing work.

Files:
- `docs/specifications/integrations/drivers/r/SPECIFICATION.md`
