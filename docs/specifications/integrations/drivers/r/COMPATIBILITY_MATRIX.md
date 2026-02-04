# R Driver Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P2

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Implemented | TLS enforced; uses openssl::ssl_connect. |
| Binary-only params | Yes | Implemented | binary_transfer=false rejected in client. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal suspension handled; fetch_size paging supported. |
| Full type matrix | Yes | Implemented | Verified encoder/decoder coverage for all TYPE_MAPPING_MATRIX.md wire types. |
| Metadata helpers | Yes | Implemented | sys.* helper queries match METADATA_SCHEMA_CONTRACT.md. |
| SQLSTATE mapping | Yes | Partial | SQLSTATE surfaced; class-prefix mapping pending. |
