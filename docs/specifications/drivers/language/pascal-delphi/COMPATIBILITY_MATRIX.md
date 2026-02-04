# Pascal/Delphi Driver Compatibility Matrix (Template)

Status: Updated (2026-02-04)

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Implemented | SBWP requires TLS (server-enforced). |
| Binary-only params | Yes | Implemented | SBWP binary-only; server rejects text. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Partial | Fetch-size paging not fully audited. |
| Full type matrix | Yes | Partial | Type coverage expanded; remaining gaps tracked. |
| Metadata helpers | Yes | Partial | sys.* helpers present but not fully audited. |
| SQLSTATE mapping | Yes | Implemented | Spec-complete mapping implemented. |
