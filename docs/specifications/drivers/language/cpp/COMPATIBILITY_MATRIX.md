# C/C++ Driver Compatibility Matrix (Template)

Status: Updated (2026-02-04)

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Implemented | TLS transport supported; required by protocol. |
| Binary-only params | Yes | Implemented | Binary encoding path implemented. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal paging supported. |
| Full type matrix | Yes | Implemented | sb_type/sb_value coverage expanded. |
| Metadata helpers | Yes | Implemented | sys.* helper API provided. |
| SQLSTATE mapping | Yes | Implemented | SQLSTATE surfaced in error context. |
