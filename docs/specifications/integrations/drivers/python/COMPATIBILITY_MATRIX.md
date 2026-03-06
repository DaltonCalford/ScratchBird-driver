# Python Driver Compatibility Matrix (Template)

Status: Updated (2026-03-06)
Priority: P0

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS policy handling | Yes | Implemented | Supports `require`/`verify-ca`/`verify-full` TLS modes and `disable` plaintext mode with deterministic coverage. |
| Binary-only params | Yes | Implemented | Driver enforces binary-only parameters. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal suspension handled; fetch_size paging supported. |
| Full type matrix | Yes | Implemented | Verified encoder/decoder coverage for all TYPE_MAPPING_MATRIX.md wire types. |
| Metadata helpers | Yes | Implemented | sys.* helper queries match METADATA_SCHEMA_CONTRACT.md. |
| SQLSTATE mapping | Yes | Implemented | Full SQLSTATE mapping with DB-API class alignment and deterministic lane coverage. |
