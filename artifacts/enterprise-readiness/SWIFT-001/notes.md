# SWIFT-001 Verification Notes

## Scope
Complete the Swift driver TLS custom-certificate transport path so that `sslrootcert`, `sslcert`, and `sslkey` no longer fail on supported platforms when Network backend is present.

## Evidence
- `artifacts/enterprise-readiness/SWIFT-001/latest_verification.log`

## Result
- `tracks/beta/drivers/swift/Sources/ScratchBird/Socket.swift`
  - `connectTls` now routes custom certificate options through `connectTlsNio` before the Network backend branch.
  - `sslcert` now loads certificate chains via `NIOSSLCertificate.fromPEMFile` and selects matching private key sources with `NIOSSLPrivateKey(file:format:passphraseCallback:)`.
  - `sslpassword` is now passed to the key loader when present, enabling encrypted key files in the Swift driver.
  - The legacy hard stop for non-supported platform builds is now only returned when NIOSSL support is unavailable.

- `tracks/beta/drivers/swift/Tests/ScratchBirdTests/ConfigTests.swift`
  - Added async connect-time enforcement tests for:
    - `sslmode=disable`
    - `binary_transfer=false`
    - `compression=zstd`

## Validation
- `swift test` passes with existing unit suites after the refactor.
- `swift test` output with transport-policy enforcement tests is recorded at `artifacts/enterprise-readiness/SWIFT-001/latest_verification.log`.

## Follow-up
- Add integration coverage for certificate-backed TLS handshakes when a cert-enabled ScratchBird endpoint is available in CI (not yet added due environment constraints).
