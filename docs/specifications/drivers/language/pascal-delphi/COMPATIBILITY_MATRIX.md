# Pascal/Delphi Driver Compatibility Matrix (Template)

Status: Updated (2026-02-22)
Build/Test: 2026-02-22 - FPC compile passes for `ScratchBird.Client.pas` with native transport default. `TlsCryptoAndPolicyTests` passes; `IntegrationTest` compiles and runs (skips when `SCRATCHBIRD_PASCAL_URL` is not set).

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Implemented | Driver enforces TLS requirement and uses native OpenSSL-backed TLS transport for connect/handshake/read/write with `sslmode` policy handling (`libssl`/`libcrypto` runtime required). |
| Binary-only params | Yes | Implemented | Driver enforces binary-only parameters. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal suspension handled; fetch_size paging supported. |
| Full type matrix | Yes | Implemented | Verified encoder/decoder coverage for all TYPE_MAPPING_MATRIX.md wire types. |
| Metadata helpers | Yes | Implemented | sys.* helper queries match METADATA_SCHEMA_CONTRACT.md. |
| SQLSTATE mapping | Yes | Partial | Class-prefix mapping only (per audit). |
