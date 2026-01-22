# Type Mapping Matrix (ScratchBird Drivers)

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define the required wire type coverage for all native ScratchBird drivers.
This list mirrors the SBWP wire type registry and the persistence rules in
ScratchBird's type specifications.

## Authoritative References

- `ScratchBird/docs/specifications/wire_protocols/scratchbird_native_wire_protocol.md`
- `ScratchBird/docs/specifications/types/DATA_TYPE_PERSISTENCE_AND_CASTS.md`

## Required Wire Types

| Wire Type | Expected Representation | Notes |
|-----------|-------------------------|-------|
| NULL_TYPE | null / None / nil | Length = -1 for NULL |
| BOOLEAN | bool | 0/1 byte |
| INT16 | 16-bit integer | Signed |
| INT32 | 32-bit integer | Signed |
| INT64 | 64-bit integer | Signed |
| FLOAT32 | 32-bit float | IEEE-754 |
| FLOAT64 | 64-bit float | IEEE-754 |
| DECIMAL | Decimal/BigDecimal | Text or binary per SBWP |
| VARCHAR | string | UTF-8 |
| CHAR | string | UTF-8 |
| BYTEA | bytes | Raw bytes |
| DATE | date | Days since 2000-01-01 |
| TIME | time | Microseconds since midnight |
| TIMESTAMP | datetime | Microseconds since epoch |
| TIMESTAMPTZ | datetime with tz | Includes offset when present |
| INTERVAL | struct/object | months, days, micros |
| UUID | string/UUID | 16-byte binary |
| JSON | string/object | UTF-8 JSON |
| JSONB | string/object | UTF-8 JSON |
| ARRAY | list/array | Text literal or binary |
| COMPOSITE | struct/tuple | Requires decoding composite payload |
| GEOMETRY | bytes/string | Engine-specific encoding |
| VECTOR | list of floats | Vector literal or binary |
| MONEY | decimal | Cents integer / 100 |
| XML | string | UTF-8 |
| INET | string/object | IP address |
| CIDR | string/object | Network prefix |
| MACADDR | string | MAC address |
| TSVECTOR | string | Text search vector |
| TSQUERY | string | Text search query |
| RANGE | object | Lower/upper bounds with flags |
| UNKNOWN | bytes | Raw fallback |

## Driver Requirements

- All drivers must decode and encode every wire type listed above.
- Composite, geometry, macaddr, and range types are required even if not
  used by the client language directly.
- Drivers may expose custom wrappers for complex types, but must preserve
  full fidelity in round-trip operations.

