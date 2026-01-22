# Native Protocol Alignment (ScratchBird Drivers)

Status: Draft
Last Updated: 2026-01-09

## Purpose

All ScratchBird drivers in this repo must speak the ScratchBird Native Wire Protocol
(SBWP) v1.1 and target native ScratchBird only. Legacy SBDB-style messages and
non-native protocols are out of scope for these drivers.

## Authoritative Reference

- `ScratchBird/docs/specifications/wire_protocols/scratchbird_native_wire_protocol.md`

## Mandatory Requirements

1. Protocol version
   - Use SBWP v1.1 only.
   - Message header is 40 bytes with magic 0x53425750 ("SBWP").

2. TLS
   - TLS 1.3 is required for all connections.
   - No plaintext fallback for production mode.
   - Drivers must surface TLS failures clearly.

3. Connection lifecycle
   - TLS handshake -> STARTUP -> AUTH -> AUTH_OK.
   - After AUTH_OK, every message must include attachment_id and txn_id.
   - Always-in-transaction semantics must be respected by the client.

4. Query model
   - Unparameterized SQL may use QUERY.
   - Parameterized SQL must use PARSE/BIND/EXECUTE.
   - No client-side SQL parameter substitution.

5. Prepared statement lifecycle
   - Implement PARSE, DESCRIBE, BIND, EXECUTE, CLOSE, SYNC.
   - Support named and unnamed statements/portals.
   - Handle row/parameter descriptions and per-column result formats.

6. Cancellation
   - Implement CANCEL messages (MSG_FLAG_URGENT).
   - Surface cancellation as a distinct error in the client API.

7. Compression
   - Optional zstd per SBWP; only when negotiated.

8. Feature gating
   - Drivers must not attempt emulated wire protocols (PostgreSQL/MySQL/Firebird).

## Legacy Protocol Deprecation

The legacy SBDB 12-byte header and message set used by the existing drivers is
not compatible with SBWP v1.1. All drivers must be migrated to SBWP.

## Conformance Tests (Required)

- Protocol handshake (TLS, STARTUP/AUTH, attachment/txn IDs)
- Simple QUERY
- PARSE/BIND/EXECUTE for each parameter type
- CANCEL behavior for long-running queries

