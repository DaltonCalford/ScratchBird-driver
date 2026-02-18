# R Driver Compatibility Matrix (Template)

Status: Updated (2026-02-06)
Build/Test: 2026-02-06 - `R CMD build .` fails (invalid DESCRIPTION DCF format).

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Implemented | Driver enforces TLS requirement. |
| Binary-only params | Yes | Implemented | Driver enforces binary-only parameters. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal suspension handled; fetch_size paging supported. |
| Full type matrix | Yes | Implemented | Verified encoder/decoder coverage for all TYPE_MAPPING_MATRIX.md wire types. |
| Metadata helpers | Yes | Implemented | sys.* helper queries match METADATA_SCHEMA_CONTRACT.md. |
| SQLSTATE mapping | Yes | Partial | Class-prefix mapping only (per audit). |
