# DLB-GO-002 S1 CONN Implementation

## What Changed

- Expanded DSN/property normalization in [`config.go`](/home/dcalford/CliWork/ScratchBird-driver/tracks/p3/drivers/go/config.go):
  - Protocol aliases (`jdbc`, `odbc`, `postgresql`, `scratchbird-native` variants) now normalize to `native`.
  - `sslmode` accepts JDBC-compatible aliases and normalizes to `disable|require|verify-ca|verify-full`.
  - `compression` accepts `off|zstd` plus aliases and rejects unknown values.
  - `binary_transfer` now uses strict bool parsing while allowing `false`.
  - Auth plugin startup fields are parsed (`auth_method_id`, `auth_payload_json`, `auth_payload_b64`, `auth_provider_profile` + aliases).
- Updated connect/auth behavior in [`conn.go`](/home/dcalford/CliWork/ScratchBird-driver/tracks/p3/drivers/go/conn.go):
  - `sslmode=disable` now bypasses TLS instead of hard-rejecting.
  - `compression=zstd` and `binary_transfer=false` are accepted.
  - `front_door_mode=manager_proxy` now fails fast with `08001` when `manager_auth_token` is missing.
  - Startup auth plugin selection is applied through protocol params.
  - Additional auth methods (`md5`, `certificate`, `gssapi/sspi`, `ldap`, `saml`, `oidc`, `mfa`, `cluster pki`) now route through generic auth payload handling.
  - Fixed `ensureOpen` lock ordering to avoid connect/handshake deadlock.
- Added always-on runtime contract coverage in [`runtime_contract_gate_test.go`](/home/dcalford/CliWork/ScratchBird-driver/tracks/p3/drivers/go/runtime_contract_gate_test.go):
  - Manager-proxy handshake/auth path with no environment dependency.
  - Startup feature-bit and query-flag assertions for compression/binary-transfer parity.

## Targeted Tests Run

- `cd /home/dcalford/CliWork/ScratchBird-driver/tracks/p3/drivers/go && go test ./...`
  - Result: `PASS`

## CONN Status Recommendation

- `IMPLEMENTED` (baseline-complete for the 0.1.0 scope).

