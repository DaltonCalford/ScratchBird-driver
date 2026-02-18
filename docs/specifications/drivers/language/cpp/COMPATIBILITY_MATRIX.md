# C/C++ Driver Compatibility Matrix (Template)

Status: Updated (2026-02-04)

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Implemented | Driver enforces TLS requirement. |
| Binary-only params | Yes | Implemented | Driver enforces binary-only parameters. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal paging supported. |
| Full type matrix | Yes | Partial | Limited coverage vs full SBWP type matrix. |
| Metadata helpers | Yes | No | No sys.* metadata helpers in public C API. |
| Statement cache | Yes | Implemented | `sb_stmt_cache_*` helpers backed by C++ cache. |
| SQLSTATE mapping | Yes | Partial | Class-prefix mapping only (per audit). |
