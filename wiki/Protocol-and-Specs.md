# Protocol and Specs

All ScratchBird drivers implement SBWP v1.1 (ScratchBird Wire Protocol).

## Protocol Overview

### Connection Lifecycle

1. TLS 1.3 handshake
2. STARTUP message
3. AUTH (SCRAM-SHA-256)
4. AUTH_OK
5. Ready for queries

After AUTH_OK, every message includes `attachment_id` and `txn_id`. Always-in-transaction semantics are enforced.

### Message Format

- 40-byte header with magic `0x53425750` ("SBWP")
- Binary payload (text mode rejected with SQLSTATE 0A000)
- Compression: zstd disabled pending server-side implementation

### Query Models

| Model | Use Case |
|-------|----------|
| QUERY | Unparameterized SQL |
| PARSE/BIND/EXECUTE | Parameterized SQL (required for parameters) |

Client-side SQL parameter substitution is prohibited.

## Prepare/Bind Requirements

### Placeholder Handling

- Drivers translate language-native placeholders to SBWP `$1` style
- Named placeholders are rewritten to positional indexes before PARSE

### Execution Flow

1. **PARSE** - Send SQL with parameter type OIDs
2. **DESCRIBE** - Retrieve parameter and result metadata
3. **BIND** - Bind parameter values (binary format)
4. **EXECUTE** - Execute with optional max_rows for paging
5. **SYNC** - Terminate portal sequence

### NULL Encoding

NULL values use length = -1 with no payload.

### Batching

Batch execution reuses PARSE and issues repeated BIND/EXECUTE cycles. No string concatenation of values.

## Type Mapping Matrix

All drivers are expected to encode and decode these wire types (spec requirement):

| Wire Type | Representation | Notes |
|-----------|---------------|-------|
| NULL_TYPE | null/None/nil | Length = -1 |
| BOOLEAN | bool | 0/1 byte |
| INT16 | 16-bit signed | |
| INT32 | 32-bit signed | |
| INT64 | 64-bit signed | |
| FLOAT32 | IEEE-754 32-bit | |
| FLOAT64 | IEEE-754 64-bit | |
| DECIMAL | Decimal/BigDecimal | Text or binary |
| VARCHAR | UTF-8 string | |
| CHAR | UTF-8 string | |
| BYTEA | Raw bytes | |
| DATE | Days since 2000-01-01 | |
| TIME | Microseconds since midnight | |
| TIMESTAMP | Microseconds since epoch | |
| TIMESTAMPTZ | With timezone offset | |
| INTERVAL | months, days, micros | |
| UUID | 16-byte binary | |
| JSON | UTF-8 JSON string | |
| JSONB | UTF-8 JSON string | |
| ARRAY | List/array | |
| COMPOSITE | Struct/tuple | |
| GEOMETRY | Engine-specific | |
| VECTOR | List of floats | |
| MONEY | Cents / 100 | |
| XML | UTF-8 | |
| INET | IP address | |
| CIDR | Network prefix | |
| MACADDR | MAC address | |
| TSVECTOR | Text search vector | |
| TSQUERY | Text search query | |
| RANGE | Lower/upper bounds | |
| UNKNOWN | Raw bytes fallback | |

## Error Mapping

### Required Error Fields

Drivers must surface:
- message
- sqlstate (when provided)
- server error code (when provided)
- retriable flag

### SQLSTATE Classes

| Class | Meaning | Retriable |
|-------|---------|-----------|
| 08 | Connection errors | Some |
| 22 | Data errors | No |
| 23 | Integrity constraint | No |
| 28 | Authorization | No |
| 40 | Transaction rollback | Yes |
| 42 | Syntax/access | No |
| 53 | Resource limits | No |
| 57 | Operator intervention | Some |

### Common SQLSTATEs

| SQLSTATE | Meaning | Retriable |
|----------|---------|-----------|
| 08001 | Cannot connect | Yes |
| 08006 | Connection failure | Yes |
| 23505 | Unique violation | No |
| 40001 | Serialization failure | Yes |
| 40P01 | Deadlock detected | Yes |
| 42601 | Syntax error | No |
| 42P01 | Undefined table | No |
| 57014 | Query canceled | Yes |

### Per-Language Error Types

| Language | Base Error Type |
|----------|-----------------|
| Go | *scratchbird.Error |
| Python | DB-API exceptions (OperationalError, IntegrityError, etc.) |
| Node.js | ScratchbirdError subclasses |
| Ruby | Scratchbird::Error subclasses |
| Rust | Error with ErrorKind |
| PHP | ScratchBirdException subclasses |
| .NET | ScratchBirdException subclasses |
| JDBC | java.sql.SQLException |

## Streaming and Paging

### Portal Paging

Large result sets are fetched incrementally using portal paging:

1. **EXECUTE** with `max_rows` limit
2. Server returns `MSG_PORTAL_SUSPENDED` when limit reached
3. Client issues another EXECUTE to fetch next batch
4. Repeat until `MSG_COMMAND_COMPLETE`

### fetch_size Configuration

Drivers support `fetch_size` (or `fetchSize`) to control rows per fetch:

```
scratchbird://host:3092/db?fetch_size=1000
```

Set to 0 (default) to fetch all rows at once.

### Language-Specific APIs

| Language | Streaming API |
|----------|---------------|
| Go | `Rows` iterator |
| Python | `Cursor.fetchmany()` |
| Node.js | `queryStream()` |
| Ruby | `ResultStream` |
| Rust | `RowStream` |
| JDBC | `setFetchSize()` |

## Cancellation

- Use CANCEL messages with MSG_FLAG_URGENT
- Surface cancellation as distinct error (SQLSTATE 57014)
- Drivers must not block indefinitely on long queries
- Timeout enforcement wired to CANCEL (e.g., .NET CommandTimeout, JDBC queryTimeout)
