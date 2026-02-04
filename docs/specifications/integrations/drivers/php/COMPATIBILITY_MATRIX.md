# PHP Driver Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P0

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Implemented | SBWP requires TLS (server-enforced). |
| Binary-only params | Yes | Implemented | SBWP binary-only; server rejects text. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal suspension handled; fetch_size paging supported. |
| Full type matrix | Yes | Implemented | Verified encoder/decoder coverage for all TYPE_MAPPING_MATRIX.md wire types. |
| Metadata helpers | Yes | Implemented | sys.* helper queries match METADATA_SCHEMA_CONTRACT.md. |
| SQLSTATE mapping | Yes | Implemented | Spec-complete mapping implemented. |
