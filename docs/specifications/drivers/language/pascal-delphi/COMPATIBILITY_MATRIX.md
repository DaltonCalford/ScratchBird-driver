# Pascal/Delphi Driver Compatibility Matrix (Template)

Status: Updated (2026-02-18)
Build/Test: 2026-02-18 - FPC compile passes for `ScratchBird.Client.pas` (native default and `SCRATCHBIRD_USE_INDY` compatibility build). `TlsCryptoAndPolicyTests` passes (SHA/HMAC/HKDF vectors + hostname/policy checks).

| Feature | Required | Status | Notes |
| --- | --- | --- | --- |
| TLS required | Yes | Partial | Driver enforces TLS requirement; native in-driver TLS now includes SHA-256/HMAC/HKDF and certificate policy validation hooks, but wire handshake/key exchange/record AEAD are still pending. |
| Binary-only params | Yes | Implemented | Driver enforces binary-only parameters. |
| Prepared statements | Yes | Implemented | PARSE/BIND/EXECUTE baseline. |
| Streaming/paging | Yes | Implemented | Portal suspension handled; fetch_size paging supported. |
| Full type matrix | Yes | Implemented | Verified encoder/decoder coverage for all TYPE_MAPPING_MATRIX.md wire types. |
| Metadata helpers | Yes | Implemented | sys.* helper queries match METADATA_SCHEMA_CONTRACT.md. |
| SQLSTATE mapping | Yes | Partial | Class-prefix mapping only (per audit). |
