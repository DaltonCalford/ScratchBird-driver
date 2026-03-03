# DLB-GO-002 S1 CONN Implementation

## What Changed

- Hardened TLS mode handling in [`conn.go`](/home/dcalford/CliWork/ScratchBird-driver/tracks/alpha/drivers/go/conn.go):
  - `applyTLS` now trims whitespace before SSL mode comparison, so values like `"  DISABLE  "` are consistently rejected as non-compliant (`TLS is required`).
  - `buildTLSConfig` now fails fast when `sslrootcert` does not contain parseable PEM certificates (`failed to parse sslrootcert PEM`), instead of silently accepting an empty CA pool.
- Added targeted connection/auth/protocol unit coverage in [`conn_protocol_test.go`](/home/dcalford/CliWork/ScratchBird-driver/tracks/alpha/drivers/go/conn_protocol_test.go):
  - Connection guardrails: unsupported protocol and `binary_transfer=false` are rejected before dialing.
  - TLS behavior: whitespace-trimmed `sslmode=disable` rejection and invalid CA PEM rejection.
  - Protocol/auth parsing: oversized header rejection, truncated `AUTH_CONTINUE` rejection, auth plugin namespace validation and param wiring.
- Updated CONN evidence anchors in [`BASELINE_REQUIREMENT_MAPPING.md`](/home/dcalford/CliWork/ScratchBird-driver/tracks/alpha/drivers/go/BASELINE_REQUIREMENT_MAPPING.md).

## Targeted Tests Run

- `cd /home/dcalford/CliWork/ScratchBird-driver/tracks/alpha/drivers/go && go test ./... -run 'TestApplyTLSDisableModeTrimsWhitespace|TestBuildTLSConfigRejectsInvalidRootCertPEM|TestConnectRejectsUnsupportedProtocolBeforeDial|TestConnectRejectsBinaryTransferFalseBeforeDial|TestDecodeHeaderRejectsPayloadTooLarge|TestParseAuthContinueRejectsTruncatedPayload|TestApplyAuthPluginSelectionRejectsInvalidNamespace|TestApplyAuthPluginSelectionSetsParams'`
  - Result: `PASS` (`ok github.com/scratchbird/scratchbird-go`, conformance package had no matching tests)

## CONN Status Recommendation

- `PARTIAL` (remains partial after this change set).

## Remaining Concrete Gaps

- `binary_transfer=false` is still explicitly unsupported in `connect`.
- `compression=zstd` is still explicitly unsupported in `connect`.
- Auth negotiation currently supports password and SCRAM-SHA-256 paths; other advertised auth methods remain unsupported.
- No lane integration test currently exercises end-to-end `manager_proxy` handshake/auth against a live manager endpoint.
