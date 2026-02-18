# Pascal/Delphi Driver TLS Implementation Spec

Status: In Progress  
Last Updated: 2026-02-18

## 1. Objective

Define a native TLS stack design for the Pascal/Delphi ScratchBird driver that is implemented in-repo and owned by the ScratchBird project.

## 2. Constraints

- Do not vendor, copy, or directly integrate `~/CliWork/TaurusTLS` implementation code.
- TaurusTLS may be used only as a behavioral reference during validation.
- TLS is mandatory for ScratchBird driver connections.
- Native parser listener remains the only supported parser endpoint (`protocol=native`).

## 3. Protocol Requirements

- TLS 1.3 required.
- TLS 1.2 optional compatibility mode for legacy environments, disabled by default.
- Mutual TLS optional via client cert/key configuration.
- No plaintext fallback once TLS is requested (and ScratchBird requires it).

## 3.1 Implementation Snapshot (2026-02-18)

Implemented in-driver now:

- `ScratchBird.Tls.Types` (core config/error types, revocation policy, socket-handle contract type).
- `ScratchBird.Tls.Crypto` (SHA-256, HMAC-SHA256, HKDF extract/expand, TLS 1.3 HKDF-Label).
- `ScratchBird.Tls.X509` policy checks (SAN/CN hostname matching, wildcard restrictions, validity window, key usage/EKU checks, revocation-policy hook).
- `ScratchBird.Tls.Handshake` ordered client-side state machine.
- `ScratchBird.Tls.RecordLayer` TLS record framing/header parsing.
- `ScratchBird.Tls.Context` lifecycle/config validation + key-schedule scaffolding + peer-policy validation hook.

Still pending:

- Native socket adapter + full handshake wire-message exchange.
- DER/PEM certificate parsing and chain-building from peer handshake messages.
- TLS 1.3 key exchange, signature verification, and traffic-key derivation.
- AEAD record encrypt/decrypt for runtime `Read`/`Write`.

## 4. Driver API Contract

The Pascal driver TLS layer must expose:

- `Initialize(const Config: TTlsConfig): TTlsStatus`
- `Handshake: TTlsStatus` and `Handshake(var SocketHandle: TSocketHandle): TTlsStatus`
- `Read(var Buffer; Count: Integer): Integer`
- `Write(const Buffer; Count: Integer): Integer`
- `Shutdown: TTlsStatus`
- `PeerInfo: TTlsPeerInfo`
- `LastError: TTlsError`

`TTlsConfig` must include:

- `Mode` (`disable|allow|prefer|require|verify_ca|verify_full`, default `require`)
- `ServerName` (SNI + hostname verification target)
- `RootCAPath`
- `ClientCertPath`
- `ClientKeyPath`
- `ClientKeyPassword`
- `MinVersion`
- `MaxVersion`
- `RevocationPolicy` (`disabled|soft_fail|hard_fail`)

## 5. Module Layout

Proposed units:

- `ScratchBird.Tls.Types` (errors, enums, config structs)
- `ScratchBird.Tls.Crypto` (hash/HMAC/KDF/random wrappers)
- `ScratchBird.Tls.X509` (cert parsing and chain validation)
- `ScratchBird.Tls.Handshake` (client handshake state machine)
- `ScratchBird.Tls.RecordLayer` (framing, encryption, integrity)
- `ScratchBird.Tls.Transport` (socket adapter + I/O)
- `ScratchBird.Tls.Context` (public API, lifecycle)

## 6. Handshake State Machine

Required states:

1. `Idle`
2. `ClientHelloSent`
3. `ServerHelloReceived`
4. `EncryptedExtensionsReceived`
5. `CertificateChainReceived`
6. `CertificateVerifyReceived`
7. `FinishedReceived`
8. `HandshakeComplete`
9. `Closed`
10. `Error`

Rules:

- Abort on any unexpected handshake message order.
- Abort on signature/certificate validation failure.
- Abort on protocol downgrade attempt.

## 7. Certificate Validation Rules

- Verify chain to configured root CA set.
- Verify validity window (`notBefore`/`notAfter`).
- Verify hostname against SAN first; CN fallback only if SAN absent.
- Reject wildcard matches outside RFC-safe scope.
- Enforce key usage and extended key usage for server authentication.
- Enforce revocation policy hook (OCSP/CRL integration point; hard-fail policy configurable).

## 8. Cipher and Key Exchange Policy

- Allow only AEAD suites approved for TLS 1.3.
- Prefer X25519 and P-256 key exchange groups.
- Disable static RSA key exchange.
- Disable legacy/insecure algorithms by default.

## 9. Session Lifecycle

- Support clean shutdown with `close_notify`.
- Detect half-closed sockets and map to retryable/non-retryable error classes.
- Session resumption tickets optional for Phase 1; interface reserved now.

## 10. Error Mapping

TLS errors must map to driver-level categories:

- `TLS_HANDSHAKE_FAILED`
- `TLS_CERTIFICATE_INVALID`
- `TLS_HOSTNAME_MISMATCH`
- `TLS_IO_ERROR`
- `TLS_PROTOCOL_ERROR`
- `TLS_CONFIG_ERROR`

Each error must carry:

- Message
- Category
- Optional alert code
- Optional system error code

## 11. Build and Runtime Targets

- Delphi (supported versions in driver matrix)
- FreePascal/Lazarus
- Linux and Windows

No mandatory external runtime dependency is allowed for core TLS behavior.

## 12. Test Contract

### Unit Tests

- Record parsing and framing boundaries
- HKDF/key schedule correctness vectors
- Certificate chain validation positive/negative cases
- Hostname matcher edge cases

### Integration Tests

- Handshake success to ScratchBird native parser listener
- mTLS success/failure cases
- Expired certificate rejection
- Wrong hostname rejection
- Unsupported protocol/cipher rejection
- Mid-stream close and reconnect behavior

### Security Regression Tests

- Downgrade attack simulation
- Alert flood handling
- Invalid record MAC/tag rejection
- Large record fragmentation handling

## 13. Delivery Phases

1. API and state machine scaffolding
2. TLS 1.3 handshake + record encryption
3. X.509 validation and hostname verification
4. Integration with `ScratchBird.Client` transport
5. Conformance and negative security test suite

## 14. Non-Goals

- Reusing TaurusTLS implementation code in production driver binaries
- Supporting non-TLS transport for ScratchBird production connections
