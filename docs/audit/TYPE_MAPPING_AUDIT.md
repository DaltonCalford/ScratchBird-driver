# Type Mapping Audit (vs TYPE_MAPPING_MATRIX.md)

Status: Draft
Last Updated: 2026-02-04

## Scope

Audited driver type codec/decoder files for explicit handlers or OID constants
matching the required wire types in `docs/specifications/TYPE_MAPPING_MATRIX.md`.
This is a static code audit (no runtime tests). It confirms presence of
explicit mappings but does not validate binary encoding correctness.

## Evidence Sources

- `cpp/include/scratchbird/client/scratchbird_client.h`
- `go/types.go`
- `node/src/types.ts`
- `python/src/scratchbird/types.py`
- `ruby/lib/scratchbird/types.rb`
- `rust/src/types.rs`
- `php/src/TypeDecoder.php`
- `r/R/types.R`
- `pascal/src/ScratchBird.Types.pas`
- `dotnet/src/ScratchBird.Data/TypeDecoder.cs`
- `jdbc/src/main/java/com/scratchbird/jdbc/SBTypeCodec.java`
- `dart/lib/src/types.dart`
- `swift/Sources/ScratchBird/Types.swift`
- `elixir/lib/scratchbird/types.ex`
- `mojo/src/scratchbird.mojo`

## Summary

- Core drivers (Go/Node/Python/Ruby/Rust/PHP/R/Pascal/.NET/JDBC) implement
  explicit mappings for complex types (JSON/JSONB, UUID, RANGE, COMPOSITE,
  GEOMETRY, VECTOR, TSVECTOR/TSQUERY, INET/CIDR, MONEY, XML, MACADDR) and arrays.
- C/C++ public C API exposes only a limited subset of the type matrix.
- Dart/Swift/Elixir/Mojo are missing large portions of the type matrix, notably
  arrays, composites, vectors, and inet/cidr/macaddr handling.

## Per-Driver Notes (Selected)

### C/C++

- `sb_type` in `cpp/include/scratchbird/client/scratchbird_client.h` only
  covers primitives plus JSON/UUID/ARRAY/INET/CIDR/MACADDR. Missing RANGE,
  COMPOSITE, GEOMETRY, VECTOR, TSVECTOR/TSQUERY, XML, MONEY wrappers.

### Dart

- Implements primitives, JSON/JSONB, UUID, geometry, and range decoding.
- Missing arrays, composite, vector literal, inet/cidr/macaddr encode/decode.

### Swift

- Implements primitives, JSON/JSONB, UUID, geometry.
- Missing arrays, composite, range encode/decode, vector literal,
  inet/cidr/macaddr encode/decode.

### Elixir

- Implements primitives, JSON/JSONB, UUID, geometry, range decode.
- Missing arrays, composite, vector literal, inet/cidr/macaddr handling.

### Mojo

- Uses Python driver bridge and does not implement native type wrappers.

## Open Gaps

1. Expand C/C++ public type coverage to full SBWP matrix.
2. Implement missing array/composite/vector/inet/cidr/macaddr support in Dart.
3. Implement missing array/composite/range/vector/inet/cidr/macaddr support in Swift.
4. Implement missing array/composite/vector/inet/cidr/macaddr support in Elixir.
5. Add native type wrappers for Mojo once the Python bridge is removed.
