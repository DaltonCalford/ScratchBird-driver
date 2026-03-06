# ODBC 3.8 Compatibility Matrix (Template)

Status: Updated (2026-02-04)
Priority: P0

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Implemented | Driver enforces TLS requirement. |
| Binary-only params | Yes | Implemented | Driver enforces binary-only parameters. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal paging supported. |
| Full type matrix | Yes | Implemented | `SQLGetTypeInfo` and catalog type parsing cover scalar, temporal, network, range, text-search, binary, and vector families. |
| Metadata helpers | Yes | Implemented | sys.* helper API provided. |
| SQLSTATE mapping | Yes | Implemented | Per-status SQLSTATE mapping is now explicit for constraint, privilege, protocol, cursor, and runtime error families. |
