# Driver Result Decoding

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define how drivers decode SBWP result values for all wire types.

## Binary-Only Requirement

Drivers must request binary results for all columns (result format codes = 1).
Text results are not permitted for conformance and must be treated as errors
unless explicitly requested by a legacy compatibility mode.

## Requirements

- All wire types must be decoded.
- If the language lacks a native type, drivers must provide a wrapper
  type or return a canonical text representation and preserve raw bytes.

## Required Wrapper Types

Drivers must return explicit wrappers for JSONB, RANGE, and GEOMETRY.
Wrappers must preserve raw binary payloads and optional parsed forms.

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

## Canonical Text Forms (Fallback Only)

- UUID: 8-4-4-4-12 hex
- JSON/JSONB/XML: UTF-8 text
- TSVECTOR/TSQUERY: textual forms defined by the server
- RANGE: text form with inclusive/exclusive markers
- VECTOR: bracketed list of floats
- GEOMETRY: WKT or server-provided canonical text
- MACADDR, INET, CIDR: canonical network strings

## SQLSTATE Codes (Decode/Result Errors)

- 22P03: invalid binary representation
- 22007: invalid datetime format
- 22003: numeric value out of range

## Per-Language Result Mapping

The expected result type mappings mirror parameter mappings and must be
fully implemented for all wire types. See:
- `docs/specifications/DRIVER_PARAMETER_ENCODING.md`

### Go

- boolean -> bool
- int* -> int16/int32/int64
- float* -> float32/float64
- decimal/money -> decimal.Decimal
- text/json/xml -> string
- jsonb -> scratchbird.JSONB
- bytea -> []byte
- date/time/timestamp -> time.Time
- interval -> time.Duration or struct
- uuid -> uuid.UUID or string
- array -> []any
- range -> scratchbird.Range[T]
- vector -> []float32
- inet/cidr/macaddr -> net.IP/net.IPNet/net.HardwareAddr
- geometry -> scratchbird.Geometry
- composite -> struct/map

### Node.js/TypeScript

- boolean -> boolean
- int32 -> number
- int64 -> bigint
- float* -> number
- decimal/money -> string
- text/json/xml -> string
- jsonb -> ScratchbirdJsonb
- bytea -> Buffer
- date/time/timestamp -> Date
- interval -> object
- uuid -> string
- array -> any[]
- range -> ScratchbirdRange<T>
- vector -> Float32Array/number[]
- inet/cidr/macaddr -> string
- geometry -> ScratchbirdGeometry
- composite -> object

### Python

- boolean -> bool
- int* -> int
- float* -> float
- decimal/money -> decimal.Decimal
- text/json/xml -> str
- jsonb -> scratchbird.types.Jsonb
- bytea -> bytes
- date -> datetime.date
- time -> datetime.time
- timestamp/timestamptz -> datetime.datetime
- interval -> datetime.timedelta or dict
- uuid -> uuid.UUID
- array -> list
- range -> scratchbird.types.Range
- vector -> list[float]
- inet/cidr -> ipaddress objects
- macaddr -> str
- geometry -> scratchbird.types.Geometry
- composite -> tuple/dict

### Ruby

- boolean -> TrueClass/FalseClass
- int* -> Integer
- float* -> Float
- decimal/money -> BigDecimal
- text/json/xml -> String
- jsonb -> Scratchbird::JSONB
- bytea -> String (BINARY)
- date/time/timestamp -> Date/Time
- interval -> Hash
- uuid -> String
- array -> Array
- range -> Scratchbird::RangeValue
- vector -> Array
- inet/cidr/macaddr -> String
- geometry -> Scratchbird::Geometry
- composite -> Hash/Struct

### Rust

- boolean -> bool
- int* -> i16/i32/i64
- float* -> f32/f64
- decimal/money -> BigDecimal
- text/json/xml -> String
- jsonb -> scratchbird::types::Jsonb
- bytea -> Vec<u8>
- date/time/timestamp -> chrono types
- interval -> struct
- uuid -> uuid::Uuid/String
- array -> Vec<Value>
- range -> scratchbird::types::Range<T>
- vector -> Vec<f32>
- inet/cidr/macaddr -> String
- geometry -> scratchbird::types::Geometry
- composite -> struct/HashMap

### PHP

- boolean -> bool
- int* -> int
- float* -> float
- decimal/money -> string/Decimal wrapper
- text/json/xml -> string
- jsonb -> ScratchBird\\PDO\\Jsonb
- bytea -> string
- date/time/timestamp -> DateTimeImmutable
- interval -> array
- uuid -> string
- array -> array
- range -> ScratchBird\\PDO\\Range
- vector -> array
- inet/cidr/macaddr -> string
- geometry -> ScratchBird\\PDO\\Geometry
- composite -> array

### R

- boolean -> logical
- int* -> integer
- float* -> numeric
- decimal/money -> character/numeric
- text/json/xml -> character
- jsonb -> sb_jsonb (S3 class)
- bytea -> raw
- date -> Date
- time/timestamp -> POSIXct
- interval -> list
- uuid -> character
- array -> list
- range -> sb_range (S3 class)
- vector -> numeric
- inet/cidr/macaddr -> character
- geometry -> sb_geometry (S3 class)
- composite -> list

### Pascal/Delphi

- boolean -> Boolean
- int* -> SmallInt/Integer/Int64
- float* -> Single/Double
- decimal/money -> Currency
- text/json/xml -> string
- jsonb -> TScratchBirdJsonb
- bytea -> TBytes
- date/time/timestamp -> TDateTime
- interval -> record
- uuid -> string
- array -> dynamic array
- range -> TScratchBirdRange
- vector -> array of Single
- inet/cidr/macaddr -> string
- geometry -> TScratchBirdGeometry
- composite -> record

### .NET

- boolean -> bool
- int* -> short/int/long
- float* -> float/double
- decimal/money -> decimal
- text/json/xml -> string
- jsonb -> ScratchBirdJsonb
- bytea -> byte[]
- date -> DateOnly
- time -> TimeOnly
- timestamp -> DateTime
- timestamptz -> DateTimeOffset
- interval -> TimeSpan/custom
- uuid -> Guid
- array -> object[]/List<T>
- range -> ScratchBirdRange<T>
- vector -> float[]
- inet/cidr/macaddr -> string
- geometry -> ScratchBirdGeometry
- composite -> object

### JDBC

- boolean -> Boolean
- int* -> Short/Integer/Long
- float* -> Float/Double
- decimal/money -> BigDecimal
- text/json/xml -> String
- jsonb -> SBJsonb
- bytea -> byte[]/Blob
- date/time/timestamp -> java.sql.Date/Time/Timestamp
- timestamptz -> OffsetDateTime
- interval -> Duration/Period
- uuid -> java.util.UUID
- array -> java.sql.Array
- range -> SBRange<T>
- vector -> float[]
- inet/cidr/macaddr -> String
- geometry -> SBGeometry
- composite -> Struct/Object[]
