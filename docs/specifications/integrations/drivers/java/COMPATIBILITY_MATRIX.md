# Java Driver Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P0

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Implemented | Driver enforces TLS requirement. |
| Binary-only params | Yes | Implemented | Driver enforces binary-only parameters. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal suspension handled; fetch_size paging supported. |
| Full type matrix | Yes | Implemented | Verified encoder/decoder coverage for all TYPE_MAPPING_MATRIX.md wire types. |
| Metadata helpers | Yes | Implemented | DatabaseMetaData maps sys.* joins; information_schema used where JDBC requires. |
| SQLSTATE mapping | Yes | Partial | Class-prefix mapping only (per audit). |
