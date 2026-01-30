# ScratchBird Driver Implementation Audit (SBWP v1.1)

Status: Complete
Last Updated: 2026-01-30
Scope: Go, Node, Python, Ruby, Rust, PHP, R, Pascal, .NET, JDBC, Superset, Metabase

## Method

Reviewed each driver implementation against the SBWP v1.1 driver specs:
- `docs/specifications/DRIVER_DSN_AND_CONFIG_STANDARD.md`
- `docs/specifications/PREPARE_BIND_REQUIREMENTS.md`
- `docs/specifications/DRIVER_STREAMING_AND_PAGING.md`
- `docs/specifications/DRIVER_CANCELLATION_TIMEOUTS.md`
- `docs/specifications/DRIVER_METADATA_JDBC_ODBC_MAPPING.md`
- `docs/specifications/DRIVER_ERROR_MAPPING.md`
- `docs/specifications/DRIVER_AUTHENTICATION_MAPPING.md`

This audit now reflects the post-remediation state. All gaps listed in the
previous audit have been addressed; remaining notes capture deliberate
deferrals (e.g., zstd compression) and test gating.

## Cross-Driver Notes (SBWP Core)

- Binary-only enforcement is now implemented across all drivers (rejects
  `binary_transfer=false` with SQLSTATE 0A000).
- Compression is intentionally disabled (rejects `compression=zstd`) until
  server-side zstd support is available.
- DESCRIBE/parameter metadata is now issued after PARSE in all drivers.
- Portal paging (`MSG_PORTAL_SUSPENDED`) resumes with `EXECUTE max_rows` in
  all streaming paths.
- DSN key coverage now includes `role`, `sslpassword`, and `fetch_size`.

## Driver-Specific Notes

- JDBC metadata (PK/FK/type info/index columns) is populated from sys.*
  where available with safe fallbacks when optional views are absent.
- Superset and Metabase drivers now align feature flags with JDBC metadata
  behavior; binary-only enforcement is enabled.

## Notes

- SBWP v1.1 protocol alignment and SCRAM auth are implemented across the
  core language drivers.
- Wrapper types (JSONB/RANGE/GEOMETRY) are implemented in all language
  drivers; the gaps listed above are focused on missing spec requirements.
