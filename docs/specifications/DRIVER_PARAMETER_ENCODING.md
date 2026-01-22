# Driver Parameter Encoding

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define how drivers encode parameters for SBWP v1.1 PARSE/BIND messages.

## Binary-Only Requirement

All parameter values must be sent in binary format. Drivers must set
param format codes to 1 (binary) for every parameter. Text format is
not permitted for conformance and must be rejected if requested by the
client API.

## Placeholder Rules

- Named parameters must be rewritten to $1, $2, ... in query text.
- Positional placeholders (?, :1, @1) must be rewritten to $1, $2, ...

## Parameter Types

- Drivers must provide type OIDs when known.
- If unknown, use 0 and let the server infer.

## NULL Handling

- NULL values are encoded with length = -1 and no payload.

## Canonical Encodings

Binary encodings are defined in:
- `ScratchBird/docs/specifications/wire_protocols/scratchbird_native_wire_protocol.md`

## Required Wrapper Types

Drivers must provide explicit wrappers for JSONB, RANGE, and GEOMETRY and
use them for parameter encoding. Wrappers must preserve the raw binary
payloads and optional parsed forms.

JSONB wrapper fields:
- raw (bytes) required
- value (optional parsed JSON)

Range wrapper fields:
- lower, upper
- lower_inclusive, upper_inclusive
- lower_infinite, upper_infinite
- empty

Geometry wrapper fields:
- wkb (bytes) required
- srid (uint32, optional)
- wkt (string, optional)

## SQLSTATE Codes (Parameter Errors)

- 22023: invalid parameter value
- 22P02: invalid text representation
- 22P03: invalid binary representation
- 22003: numeric value out of range

## Per-Language Parameter Mapping

### Go

- BOOLEAN -> bool
- INT16/INT32/INT64 -> int16/int32/int64
- UINT* -> uint8/uint16/uint32/uint64
- DECIMAL/MONEY -> decimal.Decimal (shopspring/apd)
- FLOAT32/FLOAT64 -> float32/float64
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> string
- JSONB -> scratchbird.JSONB
- BYTEA/BLOB/VARBINARY -> []byte
- DATE/TIME/TIMESTAMP/TIMESTAMPTZ -> time.Time
- INTERVAL -> time.Duration or custom struct
- UUID -> uuid.UUID or string
- ARRAY -> []any or []T
- RANGE -> scratchbird.Range[T]
- VECTOR -> []float32
- INET/CIDR -> net.IP/net.IPNet
- MACADDR -> net.HardwareAddr or string
- GEOMETRY -> scratchbird.Geometry
- COMPOSITE -> struct/map

### Node.js/TypeScript

- BOOLEAN -> boolean
- INT32 -> number (safe integer)
- INT64 -> bigint
- FLOAT32/FLOAT64 -> number
- DECIMAL/MONEY -> string or bigint + scale
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> string
- JSONB -> ScratchbirdJsonb
- BYTEA/BLOB/VARBINARY -> Buffer
- DATE/TIME/TIMESTAMP/TIMESTAMPTZ -> Date
- INTERVAL -> { months, days, micros }
- UUID -> string
- ARRAY -> any[]
- RANGE -> ScratchbirdRange<T>
- VECTOR -> Float32Array or number[]
- INET/CIDR -> string
- MACADDR -> string
- GEOMETRY -> ScratchbirdGeometry
- COMPOSITE -> object

### Python

- BOOLEAN -> bool
- INT* -> int
- FLOAT* -> float
- DECIMAL/MONEY -> decimal.Decimal
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> str
- JSONB -> scratchbird.types.Jsonb
- BYTEA/BLOB/VARBINARY -> bytes or memoryview
- DATE -> datetime.date
- TIME -> datetime.time
- TIMESTAMP/TIMESTAMPTZ -> datetime.datetime
- INTERVAL -> datetime.timedelta or dict
- UUID -> uuid.UUID or str
- ARRAY -> list/tuple
- RANGE -> scratchbird.types.Range
- VECTOR -> list[float]
- INET/CIDR -> ipaddress objects or str
- MACADDR -> str
- GEOMETRY -> scratchbird.types.Geometry
- COMPOSITE -> dict/tuple

### Ruby

- BOOLEAN -> TrueClass/FalseClass
- INT* -> Integer
- FLOAT* -> Float
- DECIMAL/MONEY -> BigDecimal
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> String
- JSONB -> Scratchbird::JSONB
- BYTEA/BLOB/VARBINARY -> String (BINARY)
- DATE -> Date
- TIME/TIMESTAMP/TIMESTAMPTZ -> Time
- INTERVAL -> Hash
- UUID -> String
- ARRAY -> Array
- RANGE -> Scratchbird::RangeValue
- VECTOR -> Array of Float
- INET/CIDR/MACADDR -> String
- GEOMETRY -> Scratchbird::Geometry
- COMPOSITE -> Hash/Struct

### Rust

- BOOLEAN -> bool
- INT* -> i16/i32/i64
- UINT* -> u16/u32/u64
- FLOAT* -> f32/f64
- DECIMAL/MONEY -> BigDecimal
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> String
- JSONB -> scratchbird::types::Jsonb
- BYTEA/BLOB/VARBINARY -> Vec<u8>
- DATE/TIME/TIMESTAMP/TIMESTAMPTZ -> chrono types
- INTERVAL -> custom struct
- UUID -> uuid::Uuid or String
- ARRAY -> Vec<Value>
- RANGE -> scratchbird::types::Range<T>
- VECTOR -> Vec<f32>
- INET/CIDR/MACADDR -> String or custom types
- GEOMETRY -> scratchbird::types::Geometry
- COMPOSITE -> struct/HashMap

### PHP

- BOOLEAN -> bool
- INT* -> int
- FLOAT* -> float
- DECIMAL/MONEY -> string or Decimal wrapper
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> string
- JSONB -> ScratchBird\\PDO\\Jsonb
- BYTEA/BLOB/VARBINARY -> string/stream
- DATE/TIME/TIMESTAMP/TIMESTAMPTZ -> DateTimeImmutable
- INTERVAL -> array
- UUID -> string
- ARRAY -> array
- RANGE -> ScratchBird\\PDO\\Range
- VECTOR -> array of float
- INET/CIDR/MACADDR -> string
- GEOMETRY -> ScratchBird\\PDO\\Geometry
- COMPOSITE -> array

### R

- BOOLEAN -> logical
- INT* -> integer
- FLOAT* -> numeric
- DECIMAL/MONEY -> character/numeric
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> character
- JSONB -> sb_jsonb (S3 class)
- BYTEA/BLOB/VARBINARY -> raw
- DATE -> Date
- TIME/TIMESTAMP/TIMESTAMPTZ -> POSIXct
- INTERVAL -> list
- UUID -> character
- ARRAY -> list
- RANGE -> sb_range (S3 class)
- VECTOR -> numeric vector
- INET/CIDR/MACADDR -> character
- GEOMETRY -> sb_geometry (S3 class)
- COMPOSITE -> list

### Pascal/Delphi

- BOOLEAN -> Boolean
- INT* -> SmallInt/Integer/Int64
- FLOAT* -> Single/Double
- DECIMAL/MONEY -> Currency
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> string
- JSONB -> TScratchBirdJsonb
- BYTEA/BLOB/VARBINARY -> TBytes/TStream
- DATE/TIME/TIMESTAMP/TIMESTAMPTZ -> TDateTime
- INTERVAL -> record
- UUID -> string
- ARRAY -> dynamic array
- RANGE -> TScratchBirdRange
- VECTOR -> array of Single
- INET/CIDR/MACADDR -> string
- GEOMETRY -> TScratchBirdGeometry
- COMPOSITE -> record

### .NET

- BOOLEAN -> bool
- INT* -> short/int/long
- FLOAT* -> float/double
- DECIMAL/MONEY -> decimal
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> string
- JSONB -> ScratchBirdJsonb
- BYTEA/BLOB/VARBINARY -> byte[]/Stream
- DATE -> DateOnly
- TIME -> TimeOnly
- TIMESTAMP -> DateTime
- TIMESTAMPTZ -> DateTimeOffset
- INTERVAL -> TimeSpan/custom
- UUID -> Guid
- ARRAY -> List<T>
- RANGE -> ScratchBirdRange<T>
- VECTOR -> float[]
- INET/CIDR/MACADDR -> string
- GEOMETRY -> ScratchBirdGeometry
- COMPOSITE -> object

### JDBC

- BOOLEAN -> Boolean
- INT* -> Short/Integer/Long
- FLOAT* -> Float/Double
- DECIMAL/MONEY -> BigDecimal
- CHAR/VARCHAR/TEXT/JSON/XML/TSVECTOR/TSQUERY -> String
- JSONB -> SBJsonb
- BYTEA/BLOB/VARBINARY -> byte[]/Blob
- DATE -> java.sql.Date
- TIME -> java.sql.Time
- TIMESTAMP -> java.sql.Timestamp
- TIMESTAMPTZ -> java.time.OffsetDateTime
- INTERVAL -> java.time.Duration/Period
- UUID -> java.util.UUID
- ARRAY -> java.sql.Array
- RANGE -> SBRange<T>
- VECTOR -> float[]
- INET/CIDR/MACADDR -> String
- GEOMETRY -> SBGeometry
- COMPOSITE -> Struct/Object[]
