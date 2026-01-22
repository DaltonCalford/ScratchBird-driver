# Driver Authentication Mapping

Status: Draft
Last Updated: 2026-01-09

## Purpose

Define how drivers map client configuration to ScratchBird native
authentication methods and how errors are surfaced.

## Supported Methods

Required:
- Password
- SCRAM-SHA-256

Optional:
- SCRAM-SHA-512
- TLS client certificate (mTLS)

## Binary-Only Requirement

Authentication messages are binary-only under SBWP v1.1. Drivers must not
attempt any text-mode auth fallback. TLS 1.3 is mandatory when sslmode
is require/verify-* and drivers must refuse plaintext.

## Mapping Rules

- Drivers must advertise supported auth methods and select the strongest
  mutually supported method offered by the server.
- If the server requires a method the driver cannot perform, the connection
  must fail with an auth error.

## Credential Sources

- user/password from DSN or config
- mTLS uses sslcert/sslkey and sslrootcert when verify-ca/verify-full is set

## SQLSTATE Codes (Auth)

- 28000: invalid authorization specification
- 28P01: invalid password (recommended)
- 28001: invalid authorization (optional)

## Per-Language Mapping

### Go

- Config: SSLMode, SSLRootCert, SSLCert, SSLKey.
- Auth errors: scratchbird.Error{Kind: ErrAuth}.

### Node.js/TypeScript

- Config: sslmode, sslrootcert, sslcert, sslkey.
- Auth errors: ScratchbirdAuthError with sqlstate 28xxx.

### Python

- Config: sslmode plus sslrootcert/sslcert/sslkey via extra.
- Auth errors: OperationalError for 28xxx; InterfaceError for missing credentials.

### Ruby

- Config: sslmode, sslrootcert, sslcert, sslkey.
- Auth errors: Scratchbird::AuthError.

### Rust

- Config: sslmode, sslrootcert, sslcert, sslkey.
- Auth errors: ErrorKind::Auth.

### PHP

- Config: sslMode, sslRootCert, sslCert, sslKey.
- Auth errors: ScratchBirdAuthException.

### R

- Config: sslmode, sslrootcert, sslcert, sslkey.
- Auth errors: raise error with sqlstate prefix 28.

### Pascal/Delphi

- Config: SSLMode, SSLRootCert, SSLCert, SSLKey.
- Auth errors: EScratchbirdAuthError.

### .NET

- Config: SSLMode (cert/key support required).
- Auth errors: ScratchBirdAuthException.

### JDBC

- Config: ssl/sslmode, sslrootcert, sslcert, sslkey, sslpassword.
- Auth errors: SQLException with SQLState 28xxx.

